//
//  DetailViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 11/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
class DetailViewModel: LoadableFeedVM, AppAdViewModel {
    @Published
    var newsItem: NewsItem?
    @Published
    var newsClosedStatus: NewsClosedStatus = .opened
    @Published
    var pollItem: PollItem?
    @Published
    var loadingState = NetworkingState.inited
    @Published
    var loadPoint: FromPoint = .inited
    @Published
    var refreshEnd: (() -> ())? = {}
    @Published
    var canSendView = false
    /* Error Message */
    @Published
    var showErrorMsg: Bool = false
    @Published
    var errorMsg: String = ""
    @Published
    var errorMsgIcon: String = ""
    @Published
    var webViewModalItem: WebViewItem?
    @Published
    var urlForWebView: URL?
    /* Payment */
    @Published
    var paymentResult: SubscriptionState = .none
    @Published
    var presentPaymentOverlay = false
    var paymentRefererUrl: URL?

    var presentLoginView: (LoginViewItem) -> Void
    /* Ad */
    var adItems = [AdItem]()
    // Detail Text Item
    @Published
    var detailedTextItems: [TextItem]?
    @Published
    var selectedTextItemId: String = ""
    @Published
    var navigationItems: [NewsItem]?
    @Published
    var user: Account?
    // MARK: Detail Media
    @Published
    var detailedMedia: DetailMedia?
    @Published
    var showDetailedMedia = false
    /**/
    @Published
    var detailedTagItem: PrimitiveItem?
    @Published
    var showTextErrorFallback = false
    
    private var disposeBag = DisposeBag()
    var subsConf: SubscriptionConfig? {
        AppConfig().getSubscriptionConfig()
    }
    /**/
    @Published
    var showDetailedImage: ImageItem?
    private let redirectable: Bool
    
    init(feedItem: FeedItem, presentLoginView: @escaping (LoginViewItem) -> Void) {
        self.redirectable = feedItem.redirectable()
        if self.redirectable {
            if let newsItemUrl = feedItem.newsItem?.redirectUrl {
                self.webViewModalItem = WebViewItem(url: newsItemUrl, dismissCallback: { _ in false })
            }
        }
        if let newsItem = feedItem.newsItem {
            self.newsItem = newsItem
            if let closedStatus = newsItem.closedStatus {
                self.newsClosedStatus = closedStatus
            }
        } else if let pollItem = feedItem.pollItem {
            self.pollItem = pollItem
        }
        
        self.presentLoginView = presentLoginView
        self.newsItem?.textItems = optimizeContentItems(for: nil)
    }
    func isRedirectable() -> Bool {
        return redirectable
    }
    func showProgress() -> Bool {
        return loadPoint != .refresh && (loadingState == .inited || loadingState == .processing) && newsClosedStatus == .opened
    }
    func checkAccountStatus() {
        let accountService = AccountService()
        self.user = accountService.getStoredUser()
    }
    func retrieveNewsItemsCombine(feedKey: String, point: FromPoint) {
        guard let itemId = self.newsItem?.id ?? self.pollItem?.id else {
            return
        }
        self.loadPoint = point
        if self.loadingState == .processing || point == .inited && loadingState == .success {
            return
        }
        let feedRequest = APIRequest()
        loadingState = .processing
        feedRequest.loadFeedItem(detailIId: itemId, with: self.getFeedType(), feedKey: feedKey, from: point)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(.parseError):
                    self.setFeedItemFailed()
                default: break
                }
            }) { item in
                self.setFeedItemSuccess(item, for: itemId)
            }
            .store(in: disposeBag)
    }
    @MainActor
    func retrieveNewsItemsAsyncAwait(feedKey: String, point: FromPoint) async {
        guard let itemId = self.newsItem?.id ?? self.pollItem?.id else {
            return
        }
        self.loadPoint = point
        if self.loadingState == .processing || point == .inited && loadingState == .success {
            return
        }
        self.loadingState = NetworkingState.processing
        
        let feedRequest = APIRequest()
        do {
            let feedItemResult = try await feedRequest.loadFeedItem(detailIId: itemId, with: self.getFeedType(), feedKey: feedKey, from: point)
            
            if let item = feedItemResult {
                self.setFeedItemSuccess(item, for: itemId)
            } else {
                self.setFeedItemFailed()
            }
        } catch {
            self.setFeedItemFailed()
        }
    }
    private func setFeedItemFailed() {
        self.loadingState = .failed
        if loadPoint == .refresh {
            self.showRetrieveError(which: .refreshErr)
        } else {
            self.showRetrieveError(which: .defaultErr)
        }
    }
    private func setFeedItemSuccess(_ item: FeedItem, for itemId: String) {
        self.loadingState = .success
        if item.type == .poll {
            self.pollItem = item.pollItem
        } else {
            self.updateNewsItemKeepFields(new: item.newsItem)
            if !self.hasText() {
                self.retrieveNewsItemHtml(id: itemId)
            }
        }
    }
    func setCanSendView(can: Bool) {
        if can != canSendView {// MARK: Send only once
            self.canSendView = can
        }
    }
    func sendItemView(feedKey: String) {
        guard let itemId = self.newsItem?.id ?? self.pollItem?.id else {
            return
        }
        let apiRequest = APIRequest()
        apiRequest.sendNewsView(detailIId: itemId, hash: newsItem?.hash, with: getFeedType(), feedKey: feedKey, extra: getDeviceAnalyticsData())
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: disposeBag)
    }
    func sendItemShareAction(urlStr: String) {
        let apiRequest = APIRequest()
        apiRequest.sendPageShareNumber(url: urlStr)
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: disposeBag)
    }
    private func updateNewsItemKeepFields(new newsItem: NewsItem?) {
        var mutableNewsItem = newsItem
        mutableNewsItem?.textItems = optimizeContentItems(for: newsItem?.textItems)
        mutableNewsItem?.onlineNum = self.newsItem?.onlineNum
        self.newsItem = mutableNewsItem
        if let closedStatus = self.newsItem?.closedStatus {
            self.newsClosedStatus = closedStatus
        }
    }
    private func getDeviceAnalyticsData() -> [String: String]? {
        let deviceInfoId = Preference.int(.deviceInfoId)
        if let deviceInfoToken = Preference.string(.deviceInfoToken), deviceInfoId > 0, !deviceInfoToken.isEmpty {
            return ["ned": "\(deviceInfoId)", "ate": deviceInfoToken]
        }
        return nil
    }
    func retrieveNewsItemHtml(id: String) {
        if self.loadingState == .processing {
            return
        }
        let apiRequest = APIRequest()
        self.loadingState = .processing
        self.showTextErrorFallback = false
        apiRequest.loadNewsItemText(id: id, which: .html)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(.parseError):
                    self.loadingState = .failed
                    self.showTextErrorFallback = true
                default: break
                }
                if self.loadingState == .processing {
                    self.loadingState = .finished
                }
            }) { newsItemText in
                if newsItemText.textType == .html {
                    self.newsItem?.textHtml = newsItemText.textHtml
                } else if newsItemText.textType == .text {
                    self.newsItem?.text = newsItemText.text
                } else if newsItemText.textType == .parsed {
                    self.newsItem?.textItems = newsItemText.textItems
                }
                self.newsItem?.textType = newsItemText.textType
                if !self.hasText() {
                    self.loadingState = .failed
                    self.showTextErrorFallback = true
                } else {
                    self.loadingState = .success
                }
            }
            .store(in: disposeBag)
    }
    private func getFeedType() -> FeedType {
        if self.pollItem != nil {
            return .poll
        }
        return .newsItem
    }
    func showRetrieveError(which: FeedErrorType) {
        switch which {
        case .refreshErr:
            self.errorMsg = "refresh_detail_error_msg"
            self.errorMsgIcon = "arrow.clockwise"
        default:
            self.errorMsg = "detail_not_loaded"
            self.errorMsgIcon = "exclamationmark.circle"
        }
        withAnimation {
            self.showErrorMsg.toggle()
        }
    }
    private func optimizeContentItems(for textItems: [TextItem]?) -> [TextItem]? {
        guard let textItems = textItems ?? self.newsItem?.textItems else {
            return nil
        }
        var contentParagraph = ""
        var optimizedTextItems = [TextItem]()
        var optimizedTextItem = TextItem(id: "0", type: .text)
        var contentTag: HTMLTag
        for textItem in textItems {
            contentTag = textItem.tag ?? .unk
            if !excludeTagFromText(tag: contentTag), let textContent = textItem.content {
                if !contentParagraph.isEmpty {
                    if textItem.tag != .lineBreak {
                        contentParagraph += "<br><br>"
                    }
                }
                contentParagraph += textContent
                optimizedTextItem = textItem
                optimizedTextItem.tag = .paragraph
                optimizedTextItem.type = .text
            } else {
                if !contentParagraph.isEmpty {
                    optimizedTextItem.content = contentParagraph
                    optimizedTextItems.append(optimizedTextItem)
                    contentParagraph = ""
                }
                optimizedTextItems.append(textItem)
            }
        }
        if !contentParagraph.isEmpty {
            optimizedTextItem.content = contentParagraph
            optimizedTextItems.append(optimizedTextItem)
            contentParagraph = ""
        }
        return optimizedTextItems
    }
    private func excludeTagFromText(tag: HTMLTag) -> Bool {
        switch tag {
        case .horizontalLine:
            return true
        default:
            return false
        }
    }
    func getID() -> String {
        if let id = self.newsItem?.id {
            return id
        }
        return pollItem?.id ?? ""
    }
    func getTitle() -> String {
        let optTitle = self.newsItem?.title ?? pollItem?.title
        if let title = optTitle {
            return title
        }
        return ""
    }
    func getDate() -> String {
        if let date = self.newsItem?.date {
            return date
        }
        return pollItem?.date ?? ""
    }
    func getDatePublished() -> String? {
        return newsItem?.datePublished
    }
    func getDateCreated() -> String? {
        return newsItem?.dateCreated
    }
    func getViewNum() -> String {
        if let viewNum = self.newsItem?.views {
            return viewNum
        }
        return pollItem?.views ?? ""
    }
    func getURL() -> URL? {
        return newsItem?.url ?? pollItem?.url
    }
    func getPageSharedCnt() -> String? {
        return self.newsItem?.sharedCnt
    }
    func getShareType() -> API.ShareType {
        if isRedirectable() {
            return .webPage
        } else if let _ = self.pollItem {
            return .pollItem
        }
        return .newsItem
    }
    func getDetailedItemName() -> String {
        let name = getURL()?.absoluteString ?? getTitle()
        return name.getSubString(maxLength: 100)
    }
    func getText() -> String {
        if let text = self.newsItem?.text {
            return text
        }
        return pollItem?.text ?? ""
    }
    func getAnalyticsParameters(_ extraParams: [String: Any]) -> [String: Any] {
        var params = extraParams
        params["status"] = String(describing: self.newsClosedStatus)
        return params
    }
    func hasText() -> Bool {
        if let newsItem = self.newsItem { //, newsClosedStatus == .opened
            if !newsItem.text.isEmptyOrNil || !newsItem.textHtml.isEmptyOrNil || !newsItem.textItems.isEmptyOrNil {
                return true
            }
            if let _ = newsItem.textUrl {
                return true
            }
        } else if let pollItem = self.pollItem {
            if !pollItem.text.isEmpty || !pollItem.short.isEmptyOrNil || !pollItem.options.isEmpty {
                return true
            }
        }
        return false
    }
    func isEmbedDetailed(embed id: String) -> Bool {
        return detailedMedia?.embed?.id == id
    }
    func presentDetailedMedia(with media: DetailMedia) {
        self.detailedMedia = media
        self.showDetailedMedia = true
    }
    func dismissDetailedMedia() {
        self.showDetailedMedia = false
        self.detailedMedia = nil
    }
    /* Ad */
    func loadAd(targets: [AdTarget], pageKey: String, newsItemId: String) {
        let apiRequest = APIRequest()
        apiRequest.loadAdItem(targets: targets, pageKey: pageKey, newsItemId: newsItemId)
            .sink(receiveCompletion: { _ in }) { response in
                var hasFullscreen = false
                for (_, var adItem) in response.adItems {
                    if adItem.target == .fullscreenDetail {
                        adItem.displayState = .readyToShow
                        hasFullscreen = true
                    }
                    self.addAdItem(adItem)
                }
                if !hasFullscreen {
                    self.makeAdItemsReady(beside: .fullscreenDetail)
                } else if !self.adItems.isEmpty {
                    self.objectWillChange.send()
                }
            }
            .store(in: disposeBag)
    }
    private func addAdItem(_ adItem: AdItem) {
        self.adItems.append(adItem)
    }
    func makeAdItemsReady(beside: AdTarget) {
        if !self.adItems.isEmpty {
            for (index, var adItem) in self.adItems.enumerated() {
                if adItem.target != beside {
                    adItem.displayState = .readyToShow
                    self.adItems[index] = adItem
                }
            }
            self.objectWillChange.send()
        }
    }
    func getAdItem(target: AdTarget) -> AdItem? {
        return self.adItems.first(where: {$0.target == target && $0.displayState != .closed && $0.displayState != .notReady})
    }
    func closeAdItemView(target: AdTarget) {
        if let index = self.adItems.firstIndex(where: { $0.target == target }) {
            self.objectWillChange.send()
            self.adItems[index].displayState = .closed
        }
    }
    func presentDetailedTextItems(_ items: [TextItem], with selectedItemId: String) {
        self.detailedTextItems = items
        self.selectedTextItemId = selectedItemId
    }
    func dismissDetailedTextItems() {
        self.detailedTextItems = nil
    }
    func presentNavigationItem(newsItem: NewsItem) {
        if navigationItems == nil {
            navigationItems = [NewsItem]()
        }
        navigationItems?.append(newsItem)
    }
    func showWebViewModal(url: URL, dismissCallback: @escaping (URL) -> Bool) {
        self.webViewModalItem = WebViewItem(url: url, dismissCallback: dismissCallback)
    }
    /* Subscription */
    func detectSubscriptionAction(for url: URL) -> Bool {
        if url.absoluteString.contains(subsConf?.buyOrSubscribeAction ?? API.Subscription.defaultBuyOrSubscribe) {
            return true
        }
        return false
    }
    func showSubscriptionWebPage(for requestUrl: URL) {
        // MARK: Add Web Authorisation GET parameters
        showWebViewModal(url: appAuthorisationVarsAsGETArgs(from: requestUrl)) { receivedUrl in
            if self.newsClosedStatus != .opened, self.detectPaymentCallbackUrl(url: receivedUrl) {
                self.verifyPayment(requestUrl)
                return true
            }
            return false
        }
    }
    private func appAuthorisationVarsAsGETArgs(from url: URL) -> URL {
        var appendedUrl = URLComponents(string: url.absoluteString)
        let queryItems = [appendedUrl?.queryItems, [
            URLQueryItem(name: "app_auth_account", value: "\(Date.currentTimeStamp)"),
            URLQueryItem(name: "app_account_id", value: "\(user?.id ?? .zero)"),
            URLQueryItem(name: "app_account_token", value: user?.token)
        ]]
            .compactMap({ $0 })
            .flatMap({ $0 })
        appendedUrl?.queryItems = queryItems
        return appendedUrl?.url ?? url
    }
    func detectPaymentCallbackUrl(url: URL) -> Bool {
        if url.absoluteString.contains(subsConf?.successUrl ?? API.Subscription.defaultSuccessUrl) {
            self.paymentResult = .paymentSuccess
            return true
        } else if url.absoluteString.contains(subsConf?.failureUrl ?? API.Subscription.defaultFailureUrl) {
            self.paymentResult = .paymentFailed
            return true
        }
        return false
        // Debug
    }
    func verifyPayment(_ requestUrl: URL) {
        if let _ = self.user {
            self.paymentRefererUrl = requestUrl
            self.presentPaymentOverlay = true
        } else { // Navigate to Sign-In form with message
            
        }
    }
    func onVerifyPaymentSuccess() {
        // MARK: On Successful Payment Retrieve News Item and Update Account Info
        self.newsClosedStatus = .opened
        retrieveNewsItemsCombine(feedKey: "payment", point: .subscribe)
    }
    func presentSearchView(with query: PrimitiveItem, type: PhraseType) {
        if type == .tag {
            Task { @MainActor in
                self.detailedTagItem = query
            }
        }
    }
}
