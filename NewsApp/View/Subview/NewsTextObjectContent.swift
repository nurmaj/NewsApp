//
//  NewsTextObjectContent.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 16/5/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct NewsTextObjectContent: View {
    let textItem: TextItem
    let parentItemId: String
    let contentSize: CGSize
    let presentNewsItem: (NewsItem) -> Void
    let presentDetailMedia: (DetailMedia) -> Void
    var placeholderMode: PlaceholderMode = .bg
    @State
    private var contentHeight = CGFloat.zero
    var body: some View {
        if let imageItem = textItem.image, textItem.type == .image {
            AsyncImage(
                url: imageItem.sd ?? imageItem.thumb,
                placeholder: {
                    if placeholderMode == .bg {
                        Color("GreyBg")
                    } else if placeholderMode == .thumb {
                        AsyncImage(
                            url: imageItem.sd ?? imageItem.thumb,
                            placeholder: {
                                Spacer()
                            }, failure:{Spacer()}
                        )
                    }
                }, failure:{Spacer()}
            )
            .aspectRatio(contentMode: .fill)
            .frame(width: contentSize.width, height: contentSize.height)
            .clipped()
            .onAppear() {
                if contentSize.height > contentHeight {
                    self.contentHeight = contentSize.height
                }
            }
            .overlay(ImageCaption(caption: imageItem.title, author: imageItem.author), alignment: .bottomTrailing)
        } else if let newsItem = textItem.newsItem, textItem.type == .newsItem {
            NewsPreviewView(newsItem: newsItem, height: $contentHeight, presentNavItem: presentNewsItem)
        } else if let embedItem = textItem.embed, textItem.type == .embed {
            EmbedView(parentId: parentItemId, embed: embedItem, vertAlignment: .top, onShowPlayer: presentDetailMedia)
        } else {
            Text("\(textItem.type.rawValue) NOT SUPPORTED YET!")
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    enum PlaceholderMode {
        case bg, thumb
    }
}
struct NewsPreviewView: View {
    var newsItem: NewsItem
    @Binding
    var height: CGFloat
    @State
    var textHeight: CGFloat = .zero
    var presentNavItem: (NewsItem) -> Void
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 8) {
                DetailTitleView(title: newsItem.title, color: Color.blue, textSize: 18)
                    .onTapGesture(perform: onNewsPreviewTap)
                ItemInfoView(date: newsItem.date, datePublished: nil, dateCreated: nil, views: newsItem.views, onlineNum: 0, showViewNum: false, paddingTop: .zero)
                if let newsUrl = newsItem.url {
                    Group {
                        Text("more_detail")
                            .foregroundColor(Color("BlackTint"))
                            .font(.callout)
                        + Text("\(newsUrl.absoluteString)")
                            .foregroundColor(Color.blue)
                            .font(.callout)
                    }
                    .padding(.horizontal, 8)
                    .onTapGesture(perform: onNewsPreviewTap)
                }
                // MARK: Need to implement dynamic height on Carousel
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear() {
                            if proxy.size.height > height {
                                self.height = proxy.size.height
                            }
                        }
                        .onChange(of: textHeight) { _ in
                            if proxy.size.height > height {
                                self.height = proxy.size.height
                            }
                        }
                }
            )
        }
    }
    private func onNewsPreviewTap() {
        withAnimation {
            presentNavItem(newsItem)
        }
    }
}
struct NewsTextObjectContent_Previews: PreviewProvider {
    static var previews: some View {
        NewsTextObjectContent(textItem: TextItem(id: "1_2", type: .newsItem, tag: .blockquote, content: nil, items: nil, link: nil, image: nil, newsItem: NewsItem(id: "1_1", title: "Some Title", title2: nil, url: URL(string: "https://newsapp.media/news/1676248"), redirectUrl: nil, textUrl: nil, timestamp: 1617689940, comments: nil, categoryId: nil, onlineNum: 201, commentStatus: nil, moderationStatus: nil, closedStatus: nil, views: "10 902", date: "4 августа 2025", datePublished: nil, dateCreated: nil, hash: nil, text: "Some text", textHtml: nil, shortText: nil, sourceName: nil, category: nil, displayType: nil, image: nil, headItem: nil, textType: .text, textItems: nil, extraText: nil, binds: nil, storyItems: nil, tags: nil), embed: nil, style: nil), parentItemId: "", contentSize: CGSize.zero, presentNewsItem: { _ in }, presentDetailMedia: { _ in })
    }
}
