//
//  FeedItemRow.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 5/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//
import SwiftUI
struct FeedItemRow: View {
    //var newsItem: Item
    //var newsItem: NewsItem
    var title: String
    var date: String
    var viewNum: String?
    var onlineNum: Int?
    var image: ImageItem?
    var itemLayout: FeedLayout
    @State
    var horizontalLayout = false
    var showViewNum: Bool
    var showClosedLock: Bool
    var isLaunchable: Bool
    //let contentWidth: CGFloat
    private var hasThumb: Bool {
        self.image?.thumb != nil
    }
    //let namespace: Namespace.ID
    var body: some View {
        /*ZStack(alignment: .topLeading) {
            Color("WhiteBlackBg")*/
        if #available(iOS 15, *) {
            rowContent
            //.overlay(CustomDivider(height: smallLayout() ? 4 : 12, color: Color("AccentLightColor")), alignment: .bottom)
            .padding(.bottom, smallLayout() ? 4 : 12)
        } else {
            rowContent
                .overlay(CustomDivider(height: smallLayout() ? 4 : 12, color: Color("AccentLightColor")), alignment: .bottom)
                //.padding(.bottom, smallLayout() ? 4 : 12)
        }
        /*}
        .padding(.bottom, horizontalLayout ? 1 : 10)*/
    }
    private var rowContent: some View {
        VStack(spacing: 0) {
            if smallLayout() {
                ItemInfoView(date: self.date, datePublished: nil, dateCreated: nil, views: self.viewNum, onlineNum: self.onlineNum ?? 0, showViewNum: showViewNum, showClosedLock: showClosedLock, isLaunchable: self.isLaunchable, paddingTop: hasThumb ? 8 : 12)
                    .padding(.bottom, hasThumb ? 2 : 6)
            }
            FeedItemView(itemLayout: itemLayout, horizontalLayout: $horizontalLayout) {
                //Group {
                //if newsItem.image != nil && newsItem.image?.outer != nil {
                if let thumb = self.image?.thumb {
                    AsyncImage(
                        url: smallLayout() ? thumb : (self.image?.sd ?? thumb),
                        placeholder: {
                            Color("GreyBg")
                                .aspectRatio(1.77, contentMode: .fit)
                        }, failure: { Spacer() }
                    )
                    .padding(.top, smallLayout() ? 4 : 0)
                    .padding(.leading, smallLayout() ? 10 : 0)
                    .scaledToFill()
                    .frame(width: smallLayout() ? 120 : getRect().width,
                           height: smallLayout() ? 120 / (16 / 9) : getRect().width / DefaultAppConfig.projectAspectRatio, alignment: .center)
                    .clipped()
                    //.transition(.opacity)
                } else if !smallLayout() {
                    Color.clear
                        .frame(height: 2)
                }
                if !smallLayout() {
                    /*FeedInfoView(date: newsItem.date, onlineNum: newsItem.onlineNum ?? 0)
                        .padding(.top, 8)*/
                    //feedInfoView()
                    ItemInfoView(date: self.date, datePublished: nil, dateCreated: nil, views: self.viewNum, onlineNum: self.onlineNum ?? 0, showViewNum: showViewNum, showClosedLock: showClosedLock, isLaunchable: self.isLaunchable)
                        .padding(.bottom, hasThumb ? 0 : 6)
                        //.matchedGeometryEffect(id: "news_item_info", in: namespace)
                    if hasThumb {
                        CustomDivider()
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                    }
                }
                Text(self.title)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 17))
                    .foregroundColor(Color("BlackTint"))
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 10)
                //}
            }
            .onRotate() { newOrientation in
                self.horizontalLayout = newOrientation == .landscapeLeft || newOrientation == .landscapeRight
            }
            .onAppear(perform: onFeedRowAppear)
            .padding(.bottom, 24)
        }
        .background(Color("WhiteBlackBg"))
    }
    private func onFeedRowAppear() {
        if UIDevice.current.orientation.isLandscape/* || screenSize.width > screenSize.height*/ { //tabItem.layoutType == .small
            self.horizontalLayout = true
        }
    }
    private func smallLayout() -> Bool {
        return itemLayout == .small || horizontalLayout
    }
}
struct FeedItemView<Content: View>: View {
    var content: Content
    let itemLayout: FeedLayout
    @Binding
    var horizontalLayout: Bool
    
    init(itemLayout: FeedLayout, horizontalLayout: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.itemLayout = itemLayout
        self._horizontalLayout = horizontalLayout
    }
    
    var body: some View {
        if itemLayout == .small || horizontalLayout {
            HStack(alignment: .top, spacing: 0) {
                content
            }
        } else {
            VStack(spacing: 0) {
                content
            }
        }
    }
}

struct FeedItemRow_Previews: PreviewProvider {
    static var previews: some View {
        //EmptyView()
        FeedItemRow(title: "Заголовок новости", date: "16:28, 04.22.2021", viewNum: "20 842", onlineNum: 209, image: ImageItem(id: "1", title: nil, author: nil, name: nil, thumb: URL(string: "https://static.newsapp.media/st_gallery/88/1141388.197e47fa1887dfadbbe8169290cfea7b.500.jpg")!, sd: URL(string: "https://static.newsapp.media/st_gallery/88/1141388.197e47fa1887dfadbbe8169290cfea7b.500.jpg"), hd: nil, sensitive: nil, width: nil, height: nil), itemLayout: .small, showViewNum: true, showClosedLock: true, isLaunchable: true)
        /*FeedItemRow(newsItem: NewsItem(id: "1_1", title: "Заголовок новости", url: nil, redirectUrl: nil, timestamp: 1617689940, comments: nil, closedStatus: nil, categoryId: nil, onlineNum: 201, status: nil, commentStatus: nil, moderationStatus: nil, views: "10 902", date: "16:28, 04.22.2021", hash: nil, text: nil, textHtml: nil, project: nil, category: nil, closedShort: nil, closedText: nil, displayType: nil, image: (try? JSONDecoder().decode(NewsItem.NewsImage.self, from: Data("{\"outer\":{\"thumb\":\"https://st-0.newsapp.media/st_gallery/88/1141388.197e47fa1887dfadbbe8169290cfea7b.500.jpg\",\"sd\":\"https://st-0.newsapp.media/st_gallery/88/1141388.197e47fa1887dfadbbe8169290cfea7b.500.jpg\"}}".utf8))), headItems: nil, textType: nil, textItems: nil, binds: nil, storyItems: nil, tags: nil), horizontalLayout: .constant(true), showViewNum: true)*/
    }
}
