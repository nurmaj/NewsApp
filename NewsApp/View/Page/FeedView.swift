//
//  FeedView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct FeedView: View {
    @StateObject
    //@ObservedObject
    var feedVM = FeedViewModel()//: FeedViewModel
    let tabItem: TabItem
    //let isLaunchPage: Bool
    @Binding
    var selectedTab: String
    @Binding
    var scrollTarget: MoveDirection?
    @Binding
    var searchModeExpanded: Bool
    @Binding
    var updatedItem: FeedItemDetail?
    /*@Binding
    var topAdItem: AdItem?*/
    /*@State
    private var topAdItemId: String?*/
    let onPresentDetail: (FeedItem, Int) -> ()
    private var tabItemId: String {
        tabItem.id
    }
    private var screenSize: CGSize {
        getRect().size
    }
    @Environment(\.scenePhase) var scenePhase
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: .zero) {
                TopBarView(leadingBtn: {}, logo: true, trailingBtn: {
                    Button(action: trailingBtnAction) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("PrimaryTint"))
                    }
                })
                if showProgress() {
                    Color("AccentLightColor")
                        .ignoresSafeArea()
                        .overlay(ProgressView())
                } else {
                    RefreshProgressView(showRefresh: $feedVM.pullRefreshing)
                    ScrollViewRefreshable(scrollTarget: $scrollTarget, header: {
                        HStack{ Spacer() }
                            .id(DefaultAppTabConfig.TOP_ITEM_ID_FOR_SCROLL)
                        if let topAdItem = self.feedVM.getAdItem(target: .topAllPage) {
                            AdView(viewModel: AdItemViewModel(adItem: topAdItem, target: topAdItem.target, from: tabItemId, closeAd: {}), frameSize: geo.size)
                                .id(topAdItem.getIDTokenString(with: tabItemId))
                        }
                    }, content: {
                        ForEach(self.feedVM.feedItems, id: \.self) { feedItem in
                            if let adItem = feedItem.adItem, adItem.target == .insideFeedItems {
                                AdView(viewModel: AdItemViewModel(adItem: adItem, target: adItem.target, from: tabItemId, closeAd: {}), frameSize: geo.size)
                                    .id(getFeedRowId(for: feedItem))
                            } else {
                                Button(action: { presentDetail(feedItem) }) {
                                    if let newsItem = feedItem.newsItem {
                                        FeedItemRow(title: newsItem.title, date: newsItem.date, viewNum: newsItem.views, onlineNum: newsItem.onlineNum, image: newsItem.image?.outer, itemLayout: getLayoutType(newsItem.displayType), showViewNum: tabItem.showViewNum, showClosedLock: newsItem.closedStatus == .paid, isLaunchable: feedItem.redirectable())
                                    } else if let pollItem = feedItem.pollItem {
                                        FeedItemRow(title: pollItem.title, date: pollItem.date, viewNum: pollItem.views, onlineNum: nil, image: pollItem.image, itemLayout: getLayoutType(pollItem.displayType), showViewNum: true, showClosedLock: false, isLaunchable: feedItem.redirectable())
                                        //}
                                    } else {
                                        EmptyView()
                                    }
                                }
                                .id(getFeedRowId(for: feedItem))
                            }
                        }
                    }, footer: {
                        if feedVM.feedItems.count >= DefaultAppConfig.ITEMS_PER_PAGE {
                            if tabItem.canScrollLoad {
                                FooterView() {
                                    if #available(iOS 15, *) {
                                        feedVM.retrieveNewsItemsCombine(feedKey: tabItemId, point: FromPoint.bottom)
                                    }
                                }
                                .id("FOOTER_VIEW_\(tabItemId)")
                            }
                        }
                    }, onFooterReach: {
                        feedVM.retrieveNewsItemsCombine(feedKey: tabItemId, point: FromPoint.bottom)
                    }, onRefreshAsync: {
                        await feedVM.retrieveNewsItemsAsyncAwait(feedKey: tabItem.id, point: FromPoint.refresh)
                    }, onRefreshClosure: { done in
                        self.feedVM.refreshEnd = {
                            done()
                        }
                        self.feedVM.retrieveNewsItemsCombine(feedKey: tabItem.id, point: FromPoint.refresh)
                    })
                }
            }
            .overlay(
                feedVM.showErrorMsg ? MsgBannerView(message: $feedVM.errorMsg, iconName: $feedVM.errorMsgIcon, show: $feedVM.showErrorMsg) : nil
                , alignment: .bottomLeading
            )
            .onReceive(feedVM.$loadingState) { state in
                if state == .inited {
                    feedVM.retrieveNewsItemsCombine(feedKey: tabItem.id)
                    // MARK: Disabled during test
                    feedVM.loadAd(targets: [.fullscreenFeed, .topAllPage, .bottomFeed], pageKey: tabItem.key, newsItemId: AdDefaults.PNID)
                } else if state != .processing {
                    if feedVM.pullRefreshing {
                        self.feedVM.pullRefreshing = false
                    }
                    self.feedVM.refreshEnd?()
                }
            }
            .onChange(of: updatedItem) { updatedItemOpt in
                if let detailedItem = updatedItemOpt {
                    feedVM.updateItemAt(pos: detailedItem.position, newItem: detailedItem.item)
                    self.updatedItem = nil
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if selectedTab == tabItemId {
                    feedVM.checkScenePhase(newPhase)
                }
            }
            .onChange(of: feedVM.pullRefreshing) { refreshing in
                if refreshing {
                    self.scrollTarget = .top
                    feedVM.retrieveNewsItemsCombine(feedKey: tabItemId, point: FromPoint.refresh)
                }
            }
            .fullScreenCover(item: .constant(feedVM.getAdItem(target: .fullscreenFeed))) { adItem in
                ZStack(alignment: .center) {
                    Color("GreyWhite").ignoresSafeArea()
                    AdView(viewModel: AdItemViewModel(adItem: adItem, target: .fullscreenFeed, from: tabItemId, closeAd: {
                        feedVM.closeAdItemView(target: .fullscreenFeed)
                        feedVM.makeAdItemsReady(beside: .fullscreenFeed)
                    }), frameSize: geo.size)
                }
            }
            .overlay(Group {
                if let adItem = feedVM.getAdItem(target: .bottomFeed) {
                    AdView(viewModel: AdItemViewModel(adItem: adItem, target: .bottomFeed, from: tabItemId, closeAd: {
                        feedVM.closeAdItemView(target: .bottomFeed)
                    }), frameSize: geo.size)
                }
            }, alignment: .bottom)
            .onAppear(perform: onFeedAppear)
        }
    }
    private func onFeedAppear() {
        
    }
    private func trailingBtnAction() {
        withAnimation(.easeInOut) {
            self.searchModeExpanded = true
        }
    }
    private func showProgress() -> Bool {
        return feedVM.loadPoint == .inited
        && (feedVM.loadingState == .inited || feedVM.loadingState == .processing)
        && feedVM.feedItems.count == 0
    }
    private func presentDetail(_ feedItem: FeedItem) {
        feedVM.cancelAPIRequest()
        onPresentDetail(feedItem, feedVM.getIndexOfItem(feedItem))
    }
    private func getLayoutType(_ itemLayoutOpt: FeedLayout?) -> FeedLayout {
        if screenSize.width > screenSize.height {
            return .small
        } else if let itemLayout = itemLayoutOpt {
            return itemLayout
        } else if let feedLayoutType = tabItem.layoutType {
            return feedLayoutType
        }
        return AppConfig.DefaultTab.DEFAULT_FEED_LAYOUT
    }
    private func getFeedRowId(for item: FeedItem) -> String {
        return "\(tabItem.id)_\(item.type?.rawValue ?? FeedType.newsItem.rawValue)_\(item.id)_\(item.adItem?.hashId ?? "0")"
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(tabItem: TabItem(key: "last", name: "", icon: IconItem(name: "last", filled: nil), canScrollLoad: true, queue: 0, iconUrl: nil, layoutType: .small, showViewNum: true), selectedTab: .constant(""), scrollTarget: .constant(nil), searchModeExpanded: .constant(false), updatedItem: .constant(nil), onPresentDetail: { (_, _) in })
    }
}
