//
//  TagView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 2/9/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct TagView: View {
    let tag: PrimitiveItem
    /*@Binding
    var isHorizontal: Bool*/
    let presentDetailItem: (NewsItem) -> Void
    let onDismiss: () -> Void
    @StateObject
    var viewModel = SearchViewModel()
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: .zero) {
                TopBarView(leadingBtn: {
                    BackButtonView(backText: tag.title, onCloseTap: onTagViewDismiss)
                }, logo: false, trailingBtn: {})
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: .zero) {
                        ForEach(viewModel.newsItems) { newsItem in
                            Button(action: { presentDetailFromTagFeed(newsItem) }) {
                                FeedItemRow(title: newsItem.title, date: newsItem.date, viewNum: newsItem.views, onlineNum: newsItem.onlineNum, image: newsItem.image?.outer, itemLayout: newsItem.displayType ?? .small, showViewNum: false, showClosedLock: newsItem.closedStatus == .paid, isLaunchable: newsItem.redirectUrl != nil)
                            }
                            .id(newsItem.id)
                        }
                        if viewModel.newsItems.count >= DefaultAppConfig.ITEMS_PER_PAGE && viewModel.bottomLoadCnt < DefaultAppConfig.bottomLoadMaxNumber {
                            FooterView {
                                viewModel.searchOnRemote(queryType: .tag, bottom: true)
                            }
                        }
                    }
                    .onAppear(perform: onTagViewAppear)
                }
            }
            .background(Color("AccentLightColor").ignoresSafeArea())
            .contentShape(Rectangle())
            .overlay(
                ProgressView()
                    .opacity(showProgressWhenEmpty() ? 1 : 0)
            )
            .overlay(ShareFloatingView(url: tag.url, shareId: tag.title, sharedCnt: nil, shareType: .tagPage, onShare: { _ in }), alignment: .bottomTrailing)
        }
    }
    private func onTagViewAppear() {
        viewModel.searchText = tag.title
        viewModel.searchOnRemote(queryType: .tag, bottom: false)
        FAnalyticsService.shared.sendLogEvent(id: tag.title, title: tag.title, type: "tag")
    }
    private func onTagViewDismiss() {
        withAnimation {
            self.onDismiss()
        }
    }
    private func presentDetailFromTagFeed(_ newsItem: NewsItem) {
        //withAnimation {
        self.presentDetailItem(newsItem)
        //}
    }
    private func showProgressWhenEmpty() -> Bool {
        return (viewModel.loadingState == .inited || viewModel.loadingState == .processing)
                && viewModel.newsItems.count == 0
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(tag: PrimitiveItem(title: "test", url: nil, label: nil, date: nil, type: nil), presentDetailItem: { _ in }, onDismiss: {})
    }
}
