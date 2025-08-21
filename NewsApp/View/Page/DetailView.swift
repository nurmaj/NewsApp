//
//  DetailView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct DetailView: View {
    @StateObject
    //@ObservedObject
    var detailVM: DetailViewModel
    @Binding
    var feedItemDetail: FeedItemDetail?
    var noTopBar = false
    var backText: String?
    //var fromTab: TabItem?
    let fromPageKey: String
    /*@Binding
    var isHorizontal: Bool*/
    @Binding
    var pushBackDisabled: Bool
    @Binding
    //var pushBackOffsetX: CGFloat
    var pushBackOffset: CGPoint
    //let topAdItem: AdItem?
    let onCloseTap: () -> Void
    //@Namespace var namespaceForDetail
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if detailVM.isRedirectable() {
                    // MARK: WebView Detail
                    WebView(urlItem: detailVM.webViewModalItem, onDismiss: onCloseTap)
                        .analyticsScreen(name: detailVM.getDetailedItemName(), class: String(describing: DetailView.self), extraParameters: detailVM.getAnalyticsParameters(["display_type" : "webview", "from_page_key": fromPageKey]))
                } else {
                    // MARK: News Item Detail
                    DetailNewsItemView(detailVM: detailVM, noTopBar: noTopBar, backText: backText, fromPageKey: fromPageKey, frameSize: geo.size, pushBackDisabled: $pushBackDisabled, pushBackOffset: $pushBackOffset/*, topAdItem: topAdItem*/, onCloseTap: onCloseTap)
                }
                // MARK: Text Item Detail
                if let detailedTextItems = detailVM.detailedTextItems {
                    ItemPager(items: detailedTextItems, selectedItemId: $detailVM.selectedTextItemId, parentItemId: detailVM.getID(), frameSize: geo.size,
                              presentNewsItem: detailVM.presentNavigationItem(newsItem:),
                              presentDetailMedia: { media in
                                 withAnimation {
                                     detailVM.detailedMedia = media
                                 }
                              },
                              onDismissTap: detailVM.dismissDetailedTextItems)
                        .zIndex(1)
                        .onAppear {
                            self.pushBackDisabled = true
                        }
                        .onDisappear {
                            self.pushBackDisabled = false
                        }
                }
                if let detailedTagItem = detailVM.detailedTagItem {
                    TagView(tag: detailedTagItem, presentDetailItem: detailVM.presentNavigationItem(newsItem:), onDismiss: {
                        detailVM.detailedTagItem = nil
                    })
                        .transition(.move(edge: .trailing))
                        .zIndex(2)
                        .onAppear {
                            self.pushBackDisabled = true
                        }
                        .onDisappear {
                            self.pushBackDisabled = false
                        }
                }
                // MARK: Detail Navigation Links
                if let navigationItems = detailVM.navigationItems {
                    VStack(spacing: 0) {
                        TopBarView(leadingBtn: {
                            BackButtonView(closeIconOnly: true, onCloseTap: dismissNavigatedDetail)
                        }, logo: false, trailingBtn: {})
                        ForEach(navigationItems) { navigationItem in
                            DetailView(detailVM: DetailViewModel(feedItem: FeedItem(newsItem: navigationItem), presentLoginView: detailVM.presentLoginView), feedItemDetail: .constant(nil), noTopBar: true, backText: nil, fromPageKey: fromPageKey, pushBackDisabled: .constant(true), pushBackOffset: .constant(CGPoint.zero)/*, topAdItem: nil*/, onCloseTap: self.dismissNavigatedDetail)
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
                // MARK: Detailed Embed Item. Using Separate Present Variable Because of Issue with DetailedMedia as presenter
                if detailVM.showDetailedMedia {
                    DetailEmbed()
                        .onAppear {
                            self.pushBackDisabled = true
                        }
                        .onDisappear {
                            self.pushBackDisabled = false
                        }
                        .zIndex(3)
                }
            }
            .environmentObject(detailVM)
        }
        .onAppear(perform: onDetailAppear)
        .onChange(of: detailVM.urlForWebView) { newUrl in
            if let urlForWebView = newUrl {
                detailVM.showWebViewModal(url: urlForWebView, dismissCallback: { _ in false })
                self.detailVM.urlForWebView = nil
            }
        }
        .onChange(of: detailVM.newsItem) { updatedNewsItem in
            if updatedNewsItem != feedItemDetail?.item.newsItem {
                feedItemDetail?.item.newsItem = updatedNewsItem
            }
        }
        .onChange(of: detailVM.pollItem) { updatedPollItem in
            if updatedPollItem != feedItemDetail?.item.pollItem {
                feedItemDetail?.item.pollItem = updatedPollItem
            }
        }
        .overlay(
            detailVM.showErrorMsg ? MsgBannerView(message: $detailVM.errorMsg, iconName: $detailVM.errorMsgIcon, show: $detailVM.showErrorMsg, paddingBottom: (safeEdges?.bottom ?? 10)) : nil
            , alignment: .bottomLeading
        )
        .background(BgShapeView())
    }
    private func dismissNavigatedDetail() {
        withAnimation {
            detailVM.navigationItems = nil
        }
    }
    private func onDetailAppear() {
        if !detailVM.isRedirectable() && !detailVM.hasText() {
            if detailVM.newsClosedStatus == .opened || detailVM.newsItem?.textUrl == nil {
                detailVM.retrieveNewsItemsCombine(feedKey: fromPageKey, point: .inited)//fromTab?.id ?? ""
            }
        } else {
            self.detailVM.loadingState = NetworkingState.success
        }
        detailVM.checkAccountStatus()
    }
}
fileprivate struct DetailNewsItemView: View {
    @StateObject
    var detailVM: DetailViewModel
    let noTopBar: Bool
    var backText: String?
    let fromPageKey: String
    let frameSize: CGSize
    @Binding
    var pushBackDisabled: Bool
    @Binding
    var pushBackOffset: CGPoint
    let onCloseTap: () -> Void
    
    var body: some View {
        VStack(spacing: .zero) {
            if !noTopBar {
                TopBarView(leadingBtn: {
                    BackButtonView(backText: backText, onCloseTap: onCloseTap)
                }, logo: false, trailingBtn: {})
            }
            ScrollViewRefreshable(scrollTarget: .constant(nil), rowBg: Color.clear, wrapVStack: false, header: {}, content: {
                /* MARK: Top Ad */
                if let topAdItem = detailVM.getAdItem(target: .topAllPage) {
                    AdView(viewModel: AdItemViewModel(adItem: topAdItem, target: topAdItem.target, from: detailVM.getID(), closeAd: {}), frameSize: frameSize)
                        .id(topAdItem.getIDTokenString(with: "detail"))
                }
                DetailTitleView(title: detailVM.getTitle())
                    .padding(.top, 10)
                    .fullScreenCover(item: .constant(detailVM.getAdItem(target: .fullscreenDetail))) { adItem in
                        if let adItem = detailVM.getAdItem(target: .fullscreenDetail) {
                            ZStack(alignment: .center) {
                                Color("GreyWhite").ignoresSafeArea()
                                AdView(viewModel: AdItemViewModel(adItem: adItem, target: .fullscreenDetail, from: detailVM.getID(), closeAd: {
                                    detailVM.closeAdItemView(target: .fullscreenDetail)
                                    detailVM.makeAdItemsReady(beside: .fullscreenDetail)
                                }), frameSize: frameSize)
                            }
                        }
                    }
                HStack(spacing: .zero) {
                    CustomDivider(width: 1, height: .infinity, color: Color("BlackTint"))
                        .padding(.leading, 10)
                    VStack(alignment: .leading, spacing: 0) {
                        if let projectName = detailVM.newsItem?.sourceName {
                            Text(projectName)
                                .foregroundColor(Color("DarkAccentColor"))
                                .font(.system(size: 13))
                                .fontWeight(.light)
                                .padding(.leading, 20)
                        }
                        ItemInfoView(date: detailVM.getDate(), datePublished: detailVM.getDatePublished(), dateCreated: detailVM.getDateCreated(), views: detailVM.getViewNum(), onlineNum: 0, showViewNum: true, paddingTop: 2)
                            .padding(.leading, 10)
                        CustomDivider(opacity: 0.4)
                            .padding(.trailing, 10)
                    }
                }
                .padding(.top, 15)
                .padding(.bottom, 10)
                if detailVM.loadingState == .success || detailVM.loadingState == .processing && !detailVM.showProgress() {
                    HStack { Spacer() }
                        .analyticsScreen(name: detailVM.getDetailedItemName(), class: String(describing: DetailView.self), extraParameters: detailVM.getAnalyticsParameters(["display_type": "detail", "from_page_key": fromPageKey]))
                        .id("DETAIL_ANALYTICS_PLACEHOLDER_\(detailVM.getID())")
                    if let headItems = detailVM.newsItem?.headItem?.items, headItems.count > 0 {
                        CarouselView(viewModel: CarouselViewModel(parentId: detailVM.getID(), items: headItems),
                                     pushBackOffsetX: $pushBackOffset.x,
                                     frameWidth: min(getRect().width, getRect().height)/*getLessFrameWidth()*/,
                                     layoutType: detailVM.newsItem?.headItem?.layoutType,
                                     presentNavItem: detailVM.presentNavigationItem(newsItem:),
                                     onCarouselPresent: { items, selectedId in
                                        detailVM.presentDetailedTextItems(items, with: selectedId)
                                    },
                                     presentDetailMedia: { media in
                                        withAnimation {
                                            detailVM.presentDetailedMedia(with: media)
                                        }
                                    })
                        .padding(.bottom, 12)
                    } else if let innerImage = detailVM.newsItem?.image?.inner {
                        ImageItemView(image: innerImage, newsItemId: detailVM.getID(),
                                        frameWidth: min(getRect().width, getRect().height),
                                        presentImageView: { (textItems, id) in
                                            detailVM.presentDetailedTextItems(textItems, with: id)
                                        })
                    }
                    // Tags
                    if let tags = detailVM.newsItem?.tags {
                        WrappingTagView(tags: tags, onTagTap: { tagItem in
                            withAnimation {
                                detailVM.presentSearchView(with: tagItem, type: .tag)
                            }
                        })
                        .padding(.horizontal, 6)
                        .padding(.bottom, 8)
                    }
                    if let pollItem = detailVM.pollItem {
                        DetailPollView(viewModel: PollViewModel(pollItem, detailVM.presentLoginView), urlForWebView: $detailVM.urlForWebView, width: frameSize.width.rounded(.up))
                            .onAppear {
                                detailVM.setCanSendView(can: true)
                            }
                    }
                    if detailVM.hasText() {
                        DetailTextView(detailVM: detailVM, pushBackOffsetX: $pushBackOffset.x, width: getLessFrameWidth())
                            .background(Color("WhiteBlackBg"))
                            .onAppear {
                                detailVM.setCanSendView(can: true)
                            }
                    }
                    if let extraText = detailVM.newsItem?.extraText {
                        HTMLTextView(text: extraText, loadUrl: nil, htmlType: .text, tag: .unk, width: getLessFrameWidth(), urlForWebView: $detailVM.urlForWebView)
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                    }
                    if let storyItems = detailVM.newsItem?.storyItems {
                        PrimitiveItemLink(primitiveItems: storyItems, urlForWebView: $detailVM.urlForWebView)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 20)
                    }
                    if let itemUrl = detailVM.getURL() {
                        Button(action: {
                            detailVM.showWebViewModal(url: itemUrl) { _ in return false }
                        }) {
                            Text("\(itemUrl)")
                                .underline()
                                .font(.system(size: 16))
                                .foregroundColor(Color("BlueLightTint"))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 10)
                        }
                    }
                } else if detailVM.showProgress() {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("GreyDark")))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                        .id(UUID())
                } else if detailVM.loadingState == .failed {
                    if detailVM.showTextErrorFallback {
                        Text("news_item_text_fallback")
                            .font(.body)
                            .foregroundColor(Color("BlackTint"))
                            .padding(.horizontal, 10)
                        if let newsUrl = detailVM.getURL() {
                            Button(action: {
                                detailVM.showWebViewModal(url: newsUrl) { _ in return false }
                            }) {
                                Text("\(newsUrl)")
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.top, 10)
                            .padding(.horizontal, 10)
                        }
                    } else {
                        VStack(alignment: .center) {
                            Image(systemName: "arrow.clockwise")
                                .renderingMode(.template)
                                .imageScale(.large)
                                .foregroundColor(Color("BlackTint"))
                            Text("feed_not_loaded")
                                .font(.body)
                                .foregroundColor(Color("BlackTint"))
                        }
                        .padding(.vertical, 10)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .onTapGesture {
                            self.detailVM.retrieveNewsItemsCombine(feedKey: fromPageKey, point: .retry)
                        }
                    }
                }
                Rectangle()
                    .fill(Color.clear)
                    .padding(.bottom, (safeEdges?.bottom ?? 10) + 6)
                    .padding(.bottom, 70)
            }, footer: {}, onFooterReach: {}, onRefreshAsync: {
                await detailVM.retrieveNewsItemsAsyncAwait(feedKey: fromPageKey, point: .refresh)
            }, onRefreshClosure: { done in
                if self.detailVM.loadingState == .processing {
                    done()
                    return
                }
                self.detailVM.refreshEnd = {
                    done()
                }
                detailVM.retrieveNewsItemsCombine(feedKey: fromPageKey, point: .refresh)
            })
            .onReceive(detailVM.$loadingState) { state in
                if state == .finished || state == .success || state == .failed {
                    self.detailVM.refreshEnd?()
                } else if state == .inited {
                    detailVM.loadAd(targets: [.fullscreenDetail, .topAllPage, .bottomDetail], pageKey: "detail", newsItemId: detailVM.getID())
                }
            }
        }
        .padding(.horizontal, (safeEdges?.left ?? .zero))
        .onReceive(detailVM.$canSendView) { can in
            if can {
                detailVM.sendItemView(feedKey: fromPageKey)
            }
        }
        .overlay(VStack(spacing: .zero) {
            HStack(spacing: .zero) {
                Spacer()
                ShareFloatingView(url: detailVM.getURL(), shareId: detailVM.getID(), sharedCnt: detailVM.getPageSharedCnt(), shareType: detailVM.getShareType(), onShare: detailVM.sendItemShareAction(urlStr:), disableSafeEdgeBottom: true)
            }
            if let adItem = detailVM.getAdItem(target: .bottomDetail), adItem.displayState != .closed {
                AdView(viewModel: AdItemViewModel(adItem: adItem, target: .bottomDetail, from: detailVM.getID(), closeAd: {
                    detailVM.closeAdItemView(target: .bottomDetail)
                }), frameSize: frameSize)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 1, height: (safeEdges?.bottom ?? 4))
            }
        }, alignment: .bottom)
        .fullScreenCover(item: $detailVM.webViewModalItem, content: { item2Load in
            WebView(urlItem: item2Load, onDismiss: { self.detailVM.webViewModalItem = nil })
                .overlay( detailVM.presentPaymentOverlay ? PaymentOverlayView(presentOverlay: $detailVM.presentPaymentOverlay, paymentResult: $detailVM.paymentResult, refererUrl: detailVM.paymentRefererUrl, user: detailVM.user, subscriptionConf: detailVM.subsConf, onDismiss: { state in
                    if state == .success {
                        self.detailVM.webViewModalItem = nil
                        detailVM.onVerifyPaymentSuccess()
                    } else { // Dismissed with failed verify
                        self.detailVM.webViewModalItem = nil
                    }
                }) : nil)
        })
    }
    private func getLessFrameWidth() -> CGFloat {
        return min(frameSize.width.rounded(.up), frameSize.height.rounded(.up))
    }
}
struct DetailEmbed: View {
    @EnvironmentObject
    var detailVM: DetailViewModel
    var body: some View {
        if let detailedMedia = detailVM.detailedMedia {
            if let videoPath = detailedMedia.embed?.path {
                VideoPlayerView(
                    viewModel:
                        PlayerViewModel(videoPath: videoPath, posterImage: detailedMedia.placeholderImage, shareUrl: detailedMedia.embed?.url, videoRect: detailedMedia.embed?.getRect() ?? CGSize.zero, parentId: detailVM.getID(), id: detailedMedia.embed?.id ?? "0"),
                    dismissPlayer: {
                        withAnimation(.easeInOut) {
                            detailVM.dismissDetailedMedia()
                        }
                    })
                .transition(.move(edge: .bottom))
            }
        }
    }
}
struct DetailTitleView: View {
    var title: String
    var color: Color = Color("DarkerAccentColor")
    var textSize: CGFloat = 22
    var body: some View {
        Text(title)
            .padding(.horizontal, 10)
            .lineLimit(nil)
            .font(.system(size: textSize, weight: .bold, design: .default))
            .foregroundColor(color)
            .multilineTextAlignment(.leading)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
    }
}
struct DetailTextView: View {
    @StateObject
    var detailVM: DetailViewModel
    @Binding
    var pushBackOffsetX: CGFloat
    var width: CGFloat
    var body: some View {
        switch detailVM.newsItem?.textType {
        case .text:
            if !detailVM.getText().isEmpty {
                Text(detailVM.getText())
                    .font(.body)
                    .foregroundColor(Color("BlackTint"))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 20)
            }
        case .html:
            if let htmlText = detailVM.newsItem?.textHtml {
                HTMLTextView(text: htmlText, loadUrl: nil, htmlType: .html, tag: .unk, width: width, urlForWebView: $detailVM.urlForWebView)
            }
        case .parsed:
            if let textItems = detailVM.newsItem?.textItems {
                TextItemsContent(textItems: textItems, detailVM: detailVM, pushBackOffsetX: $pushBackOffsetX, width: width)
            }
        default:
            EmptyView()
        }
        
        if let textUrl = detailVM.newsItem?.textUrl {
            HTMLTextView(text: "", loadUrl: textUrl, htmlType: .html, tag: .unk, width: width, urlForWebView: $detailVM.urlForWebView, loadUrlOnce: true, navActionHandler: { requestUrl in
                if !detailVM.detectSubscriptionAction(for: requestUrl) {
                    detailVM.showWebViewModal(url: requestUrl, dismissCallback: { _ in false })
                    return
                }
                // Request authorization first if no account
                if let _ = detailVM.user {
                    withAnimation {
                        detailVM.showSubscriptionWebPage(for: requestUrl)
                    }
                } else {
                    withAnimation {
                        detailVM.presentLoginView(LoginViewItem(onSignIn: { account in
                            withAnimation {
                                detailVM.user = account
                                detailVM.showSubscriptionWebPage(for: requestUrl)
                            }
                        }, onDismiss: {
                            
                        }, bannerMsg: "subscribe_auth_required"))
                    }
                }
            })
            .padding(.bottom, 20)
        }
    }
}
private struct ListItemsView: View {
    let listItems: [TextItem]
    @StateObject
    var detailVM: DetailViewModel
    @Binding
    var pushBackOffsetX: CGFloat
    var width: CGFloat
    var body: some View {
        ForEach(listItems) { listItem in
            if let textContent = listItem.content {
                HTMLTextView(text: textContent, loadUrl: nil, htmlType: .text, tag: listItem.tag ?? .unk, width: width, urlForWebView: $detailVM.urlForWebView)
                    .padding(.bottom, 20)
            }
        }
    }
}
private struct TextItemsContent: View {
    let textItems: [TextItem]
    @StateObject
    var detailVM: DetailViewModel
    @Binding
    var pushBackOffsetX: CGFloat
    var width: CGFloat
    var parentType: TextItemType = .unk
    var body: some View {
        ForEach(textItems, id: \.self) { textItem in
            ParagraphContent(textItem: textItem, detailVM: detailVM, pushBackOffsetX: $pushBackOffsetX, width: width)
                .id("DETAIL_TEXT_PARAGRAPH_\(textItem.id)")
        }
    }
    struct ParagraphContent: View {
        let textItem: TextItem
        @StateObject
        var detailVM: DetailViewModel
        @Binding
        var pushBackOffsetX: CGFloat
        var width: CGFloat
        var parentTag: HTMLTag?
        var parentType: TextItemType = .unk
        var prefixText: String?
        var body: some View {
            if let textContent = textItem.content {
                HTMLTextView(text: "\(prefixText ?? "")\(textContent)", loadUrl: nil, htmlType: .text, tag: textItem.tag ?? .unk, parentTag: parentTag, width: width, urlForWebView: $detailVM.urlForWebView)
                    .padding(.bottom, 18)
            } else if let items = textItem.items, textItem.type == .gallery {
                CarouselView(viewModel: CarouselViewModel(parentId: detailVM.getID(), items: items),
                             pushBackOffsetX: $pushBackOffsetX,
                             frameWidth: min(getRect().width, getRect().height),
                             layoutType: textItem.layoutType,
                             topSeparator: true,
                             presentNavItem: detailVM.presentNavigationItem(newsItem:),
                             onCarouselPresent:  { items, selectedId in
                                    detailVM.presentDetailedTextItems(items, with: selectedId)
                }, presentDetailMedia: { media in
                    withAnimation {
                        detailVM.presentDetailedMedia(with: media)
                    }
                })
                .padding(.bottom, 10)
            } else if let embedItem = textItem.embed, textItem.type == .embed {
                EmbedView(parentId: detailVM.getID(), embed: embedItem, vertAlignment: .top, onShowPlayer: { media in
                    withAnimation {
                        detailVM.presentDetailedMedia(with: media)
                    }
                })
                    .padding(.bottom, 20)
                    .contentShape(Rectangle())
            } else if let listItems = textItem.items {
                if textItem.tag == .ol {
                    EnumeratedForEach(listItems) { (idx, item) in
                        ParagraphContent(textItem: item, detailVM: detailVM, pushBackOffsetX: $pushBackOffsetX, width: width, parentTag: textItem.tag, prefixText: "\(idx + 1). ")
                    }
                } else {
                    TextItemsContent(textItems: listItems, detailVM: detailVM, pushBackOffsetX: $pushBackOffsetX, width: width, parentType: textItem.type)
                        .simultaneousGesture( textItem.type == .link ? TapGesture().onEnded({ onTextItemLinkTap(textItem) }) : nil )
                }
            } else if let imageItem = textItem.image {
                ImageItemView(image: imageItem, newsItemId: detailVM.getID(),
                                frameWidth: min(getRect().width, getRect().height),
                                presentImageView: { (items, id) in
                                    detailVM.presentDetailedTextItems(items, with: id)
                }, disableViewer: parentType == .link)
            } else if textItem.type == .link {
                
            } else { // Show Unsupported fallback
                UnsupportedItemView()
            }
        }
        private func onTextItemLinkTap(_ item: TextItem) {
            if let link = item.link {
                detailVM.urlForWebView = link
            }
        }
    }
}
private struct PrimitiveItemLink: View {
    let primitiveItems: [PrimitiveItem]
    @Binding
    var urlForWebView: URL?
    @State
    private var maxDateWidth = CGFloat.zero
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("read_more_topic")
                .font(.callout)
                .fontWeight(.semibold)
            ForEach(primitiveItems, id: \.self) { item in
                Button(action: { onPrimitiveLinkTap(item.url) }) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        if let date = item.date {
                            Text("\(date)")
                                .font(.caption)
                                .foregroundColor(Color("GreyFont"))
                                .frame(minWidth: maxDateWidth)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                if geo.size.width > maxDateWidth {
                                                    self.maxDateWidth = min(geo.size.width, DefaultAppConfig.primitiveLinkDateWidth)
                                                }
                                            }
                                    }
                                )
                        }
                        Text("\(item.title)")
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(CustomDivider(), alignment: .top)
                }
            }
        }
        .foregroundColor(Color("BlackTint"))
    }
    private func onPrimitiveLinkTap(_ itemLink: URL?) {
        if let link = itemLink {
            self.urlForWebView = link
        }
    }
}
private struct DetailPollView: View {
    @StateObject
    var viewModel: PollViewModel
    @Binding
    var urlForWebView: URL?
    @EnvironmentObject
    var stateVM: StateViewModel
    var width: CGFloat
    var body: some View {
        LazyVStack(spacing: 0) {
            if viewModel.hasExpired() {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("poll_expired")
                        .padding(.top, 2)
                        .font(.callout)
                }
                .padding(.top, 16)
                .foregroundColor(Color("ErrorTint"))
            }
            HStack(spacing: 4) {
                Text("total_votes")
                    .font(.body)
                Text("\(String(viewModel.pollItem.totalVotes))")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(Color("BlackTint"))
            .padding(.top, 20)
            .padding(.bottom, 10)
            ForEach(viewModel.pollItem.options) { option in
                PollOptionView(viewModel: viewModel, optionItem: option)
            }
            HTMLTextView(text: viewModel.pollItem.text, loadUrl: nil, htmlType: .text, tag: .text, width: width, urlForWebView: $urlForWebView)
                .padding(.vertical, 16)
        }
        .onChange(of: viewModel.alertState) { newState in
            if newState == .form {
                stateVM.presentAlert(contentItem: SheetAlertContent(title: AlertText(text: "confirm_vote_select", textFont: .body, textWeight: .regular), message: AlertText(text: LocalizedStringKey(viewModel.selectedOption?.title ?? ""), textWeight: .regular, sysIcName: "checkmark.circle.fill", fgColor: Color("PrimaryColor")), messageType: .label, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: dismissPollAlert), actionBtn: CustomAlertButton(text: "vote", textWeight: .semibold, type: .cancelBtn, action: viewModel.sendPollVote)))
            } else if viewModel.alertState != stateVM.alertState {
                stateVM.setAlertState(newState)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if viewModel.alertState == .failed {
                        dismissPollAlert()
                    }
                }
            }
        }
        .onChange(of: viewModel.resultMsg) { msg in
            stateVM.setResultMsg(msg)
        }
    }
    func dismissPollAlert() {
        withAnimation(.easeInOut) {
            self.viewModel.alertState = .none
            self.viewModel.selectedOption = nil
        }
    }
}
private struct PollOptionView: View {
    @StateObject
    var viewModel: PollViewModel
    let optionItem: PollOptionItem
    @State
    var percentMaxWidth: CGFloat = 8
    @State
    var percentWidth: CGFloat = 8
    var body: some View {
        Button(action: pollOptionTaped) {
            HStack(alignment: .top, spacing: 4) {
                getIconView()
                HStack(spacing: 0) {
                    Text(optionItem.title)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 18)
                .overlay(percentView()
                    , alignment: .bottomLeading)
                if !viewModel.hideResultBeforeVote() {
                    VStack(spacing: 2) {
                        Text("\(optionItem.percent)%")
                            .font(.callout)
                            .padding(.top, 2)
                        Text("(\(String(optionItem.num)))")
                            .font(.callout)
                            .frame(height: 14)
                    }
                }
            }
            .foregroundColor(viewModel.optionHasVote(option: optionItem.id) ? Color("PrimaryColor") : Color("BlackTint"))
            .padding(.top, 12)
            .padding(.leading, 20)
            .padding(.trailing, 12)
        }
        .onAppear {
            
        }
    }
    func pollOptionTaped() {
        if !viewModel.hasVoted() &&
            viewModel.pollItem.canVote &&
            !viewModel.hasExpired()
        {
            if !viewModel.pollItem.anonymousVoting && viewModel.user == nil {
                viewModel.presentLoginView(LoginViewItem(onSignIn: {_ in}, onDismiss: {}, bannerMsg: "poll_auth_required"))
                return
            }
            withAnimation(.easeInOut) {
                viewModel.selectedOption = optionItem
                viewModel.alertState = .form
            }
        } else {
            
        }
    }
    @ViewBuilder
    func getIconView() -> some View {
        if viewModel.hasVoted() && !viewModel.optionHasVote(option: optionItem.id) {
            Color.clear
                .frame(width: 24, height: 24)
                .padding(.trailing, 2)
        } else if viewModel.optionHasVote(option: optionItem.id) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.trailing, 2)
        } else if viewModel.pollItem.canVote && !viewModel.hasExpired() {
            Image(systemName: "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.trailing, 2)
        }
    }
    @ViewBuilder
    func percentView() -> some View {
        if viewModel.hideResultBeforeVote() {
            CustomDivider(color: Color("GreyLight"))
        } else {
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                    .frame(width: self.percentWidth)
                    .onAppear {
                        withAnimation(.linear) {
                            self.percentMaxWidth = geo.size.width
                            setPercentWidth()
                        }
                    }
            }
            .frame(height: 8, alignment: .bottom)
        }
    }
    private func setPercentWidth() {
        let numPercent = CGFloat(optionItem.num) / CGFloat(viewModel.pollItem.totalVotes) * 100
        var percentWidth = ((numPercent / 100) * self.percentMaxWidth) + 8
        if percentWidth > self.percentMaxWidth {
            percentWidth = self.percentMaxWidth
        }
        self.percentWidth = percentWidth
    }
}
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(detailVM: DetailViewModel(feedItem: FeedItem(id: "1", title: "1", type: .newsItem), presentLoginView: {_ in}), feedItemDetail: .constant(nil), fromPageKey: "preview", pushBackDisabled: .constant(false), pushBackOffset: .constant(CGPoint.zero), onCloseTap: {})
    }
}
