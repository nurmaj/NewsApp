//
//  FeedViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/12/20.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Combine

class FeedViewModel: LoadableFeedVM, AppAdViewModel {
    @Published
    var feedItems = [FeedItem]()
    private var disposeBag = DisposeBag()
    @Published
    var loadingState = NetworkingState.inited
    @Published
    var loadPoint: FromPoint = .inited
    @Published
    var refreshEnd: (() -> ())? = {}
    /* Error Message */
    @Published
    var showErrorMsg = false
    @Published
    var errorMsg = ""
    @Published
    var errorMsgIcon = ""
    /**/
    @Published
    var pullRefreshing = false
    @Published
    var lastScenePhase: ScenePhase = .active
    @Published
    var bgModeTime: Int64?
    /* Ad */
    var adItems = [AdItem]()
    private var user: Account? {
        let accountService = AccountService()
        return accountService.getStoredUser()
    }
    
    func retrieveNewsItemsCombine(feedKey: String, point: FromPoint = .inited) {
        self.loadPoint = point
        if loadingState == .processing || point == .inited && loadingState == .success {
            return
        }
        self.loadingState = NetworkingState.processing
        
        let feedRequest = APIRequest()
        var downTimestamp: Int?
        if point == FromPoint.bottom {
            downTimestamp = feedItems.last(where: {$0.newsItem != nil})?.newsItem?.timestamp
        }
        feedRequest.loadFeedItems(itemsKey: feedKey, setLaunchData: feedPageIsLaunch(point: point, pageKey: feedKey), downTimestamp: downTimestamp, upTimestamp: nil)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(.parseError):
                    self.setFeedItemsFailed()
                default: break
                }
            }) { feedItems in
                self.setFeedItemsSuccess(feedItems)
            }
            .store(in: disposeBag)
    }
    
    @MainActor
    func retrieveNewsItemsAsyncAwait(feedKey: String, point: FromPoint = .inited) async {
        self.loadPoint = point
        if loadingState == .processing || point == .inited && loadingState == .success {
            return
        }
        self.loadingState = NetworkingState.processing
        
        let feedRequest = APIRequest()
        var downTimestamp: Int?
        if point == FromPoint.bottom {
            downTimestamp = feedItems.last(where: {$0.newsItem != nil})?.newsItem?.timestamp
        }
        
        do {
            let feedItemsResult = try await feedRequest.loadFeedItems(itemsKey: feedKey, setLaunchData: feedPageIsLaunch(point: point, pageKey: feedKey), downTimestamp: downTimestamp, upTimestamp: nil)
            
            if let feedItems = feedItemsResult {
                self.setFeedItemsSuccess(feedItems)
            } else {
                self.setFeedItemsFailed()
            }
        } catch {
            self.setFeedItemsFailed()
        }
    }
    private func setFeedItemsFailed() {
        self.loadingState = NetworkingState.failed
        if self.loadPoint == .refresh {
            self.showRetrieveError(which: .refreshErr)
        } else {
            self.showRetrieveError(which: .defaultErr)
        }
    }
    private func setFeedItemsSuccess(_ feedItems: [FeedItem]) {
        if loadPoint == .bottom {
            self.feedItems += feedItems
        } else if loadPoint == .top {
            self.feedItems = feedItems + self.feedItems
        } else {
            self.feedItems = feedItems
        }
        self.loadingState = NetworkingState.success
    }
    private func feedPageIsLaunch(point: FromPoint, pageKey: String) -> Bool {
        if point != .inited && point != .refresh && point != .retry {
            return false
        }
        return AppConfig().getLaunchTabItem()?.key == pageKey
    }
    func showRetrieveError(which: FeedErrorType) {
        switch which {
        case .refreshErr:
            self.errorMsg = "refresh_feed_error_msg"
            self.errorMsgIcon = "arrow.clockwise"
        default:
            self.errorMsg = "feed_not_loaded"
            self.errorMsgIcon = "exclamationmark.circle"
        }
        withAnimation {
            self.showErrorMsg.toggle()
        }
    }
    func checkScenePhase(_ current: ScenePhase) {
        if current == .background {
            updateBgModeTime(currentTime: true)
        } else if current == .active && lastScenePhase != .active {
            checkBgModeTime()
        }
        self.lastScenePhase = current
    }
    func updateBgModeTime(currentTime: Bool) {
        if currentTime {
            self.bgModeTime = Date.currentTimeStamp
        } else {
            self.bgModeTime = nil
        }
    }
    func checkBgModeTime() {
        if let bgModeTime = self.bgModeTime {
            let timePassed = Date.currentTimeStamp - bgModeTime
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH"
            dateFormatter.timeZone = TimeZone(abbreviation: "KGT")
            let hourOpt = Int(dateFormatter.string(from: Date()))
            if let hour = hourOpt {
                if timePassed > 1800 && hour >= 8 && hour <= 23 || timePassed > 7200 {
                    timeToRefresh()
                }
            }
            updateBgModeTime(currentTime: false)
        }
    }
    private func timeToRefresh() {
        self.pullRefreshing = true
    }
    func loadAd(targets: [AdTarget], pageKey: String, newsItemId: String) {
        let apiRequest = APIRequest()
        apiRequest.loadAdItem(targets: targets, pageKey: pageKey, newsItemId: newsItemId)
            .sink(receiveCompletion: { _ in }) { response in
                var hasFullscreen = false
                for (_, var adItem) in response.adItems {
                    if adItem.target == .fullscreenFeed {
                        adItem.displayState = .readyToShow
                        hasFullscreen = true
                    }
                    self.addAdItem(adItem)
                }
                if !hasFullscreen {
                    self.makeAdItemsReady(beside: .fullscreenFeed)
                } else if !self.adItems.isEmpty {
                    self.objectWillChange.send()
                }
            }
            .store(in: disposeBag)
    }
    
    func getAdItem(target: AdTarget) -> AdItem? {
        return self.adItems.first(where: {$0.target == target && $0.displayState != .closed && $0.displayState != .notReady})
    }
    func addAdItem(_ adItem: AdItem) {
        self.adItems.append(adItem)
    }
    func closeAdItemView(target: AdTarget) {
        if let index = self.adItems.firstIndex(where: { $0.target == target }) {
            self.objectWillChange.send()
            self.adItems[index].displayState = .closed
        }
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
    func cancelAPIRequest() {
        disposeBag.cancel()
        Task { @MainActor in
            self.loadingState = NetworkingState.finished
        }
    }
    func getFirstItem() -> FeedItem? {
        return feedItems.count > 0 ? feedItems[0] : nil
    }
    func getIndexOfItem(_ item: FeedItem) -> Int {
        return feedItems.firstIndex(where: { $0.id == item.id && $0.secondaryId == item.secondaryId }) ?? .zero
    }
    func updateItemAt(pos: Int, newItem: FeedItem) {
        if pos > -1 && pos < feedItems.count && feedItems[pos].secondaryId == newItem.secondaryId {
            self.feedItems[pos] = newItem
        }
    }
}
