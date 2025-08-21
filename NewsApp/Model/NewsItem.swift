//
//  NewsItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 5/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//
import Foundation
struct NewsItem: Identifiable {
    let id: String
    var title: String
    let title2: String?
    let url, redirectUrl, textUrl: URL?
    let timestamp: Int
    var comments, categoryId, onlineNum, commentStatus, moderationStatus: Int?
    let closedStatus: ClosedStatus?
    var views, sharedCnt: String?
    
    var date: String
    let datePublished: String?
    let dateCreated: String?
    var hash, text, textHtml, shortText, sourceName, category: String?
    
    let displayType: FeedLayout?
    let image: NewsImage?
    var headItem: NewsHeadItem?
    var textType: TextType?
    var textItems: [TextItem]?
    var extraText: String?
    
    let binds, storyItems: [PrimitiveItem]?
    let tags: [PrimitiveItem]?
}
extension NewsItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, title, title2, sourceName="project"
        case timestamp, date = "date_updated", datePublished = "date_published", dateCreated = "date_created"
        case url, redirectUrl = "redirect_url", textUrl="text_url"
        case views = "cnt_view", sharedCnt = "shared_cnt"
        case image, headItem = "head_item"
        case comments = "cnt_comm", commentStatus = "comm", moderationStatus = "mod_status"
        case hash = "k"
        case text, textHtml = "text_html", shortText="short_text", textItems = "text_items", textType = "text_type", extraText = "extra_text"
        case onlineNum = "online"
        case closedStatus = "closed"
        case category, categoryId = "category_id"
        case binds = "bind", storyItems = "story_net"
        case tags
        case displayType = "display_type"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        title2 = try values.decodeIfPresent(String.self, forKey: .title2)
        url = try values.decodeIfPresent(URL.self, forKey: .url)
        redirectUrl = try values.decodeIfPresent(URL.self, forKey: .redirectUrl)
        textUrl = try values.decodeIfPresent(URL.self, forKey: .textUrl)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        do {
            timestamp = try Int(values.decode(String.self, forKey: .timestamp)) ?? 0
        } catch DecodingError.typeMismatch {
            timestamp = try values.decode(Int.self, forKey: .timestamp)
        }
        if let viewStr = try? values.decodeIfPresent(String.self, forKey: .views) {
            views = viewStr
        } else if let viewNum = try values.decodeIfPresent(Int.self, forKey: .views) {
            views = String(viewNum)
        }
        
        sharedCnt = try values.decodeIfPresent(String.self, forKey: .sharedCnt)
        comments = try values.decodeIfPresent(Int.self, forKey: .comments)
        hash = try values.decodeIfPresent(String.self, forKey: .hash)
        
        date = try values.decodeIfPresent(String.self, forKey: .date) ?? "0"
        
        if date == "0" {
            date = timestamp.toFormattedDate()
        }
        datePublished = try values.decodeIfPresent(String.self, forKey: .datePublished)
        dateCreated = try values.decodeIfPresent(String.self, forKey: .dateCreated)
        
        textType = try values.decodeIfPresent(TextType.self, forKey: .textType)
        closedStatus = try values.decodeIfPresent(ClosedStatus.self, forKey: .closedStatus)
        
        do {
            categoryId = try values.decodeIfPresent(Int.self, forKey: .categoryId)
        } catch DecodingError.typeMismatch {
            categoryId = try? Int(values.decodeIfPresent(String.self, forKey: .categoryId) ?? "0")
        }
        category = try values.decodeIfPresent(String.self, forKey: .category)
        onlineNum = try values.decodeIfPresent(Int.self, forKey: .onlineNum)
        commentStatus = try values.decodeIfPresent(Int.self, forKey: .commentStatus)
        moderationStatus = try values.decodeIfPresent(Int.self, forKey: .moderationStatus)
        textHtml = try values.decodeIfPresent(String.self, forKey: .textHtml)
        shortText = try values.decodeIfPresent(String.self, forKey: .shortText)
        sourceName = try values.decodeIfPresent(String.self, forKey: .sourceName)
        displayType = try values.decodeIfPresent(FeedLayout.self, forKey: .displayType)
        
        image = try values.decodeIfPresent(NewsImage.self, forKey: .image)
        headItem = try values.decodeIfPresent(NewsHeadItem.self, forKey: .headItem)
        do {
            textItems = try values.decodeIfPresent([TextItem].self, forKey: .textItems)
        } catch { // DecodingError.typeMismatch

        }
        binds = try values.decodeIfPresent([PrimitiveItem].self, forKey: .binds)
        storyItems = try values.decodeIfPresent([PrimitiveItem].self, forKey: .storyItems)
        tags = try values.decodeIfPresent([PrimitiveItem].self, forKey: .tags)
        extraText = try values.decodeIfPresent(String.self, forKey: .extraText)
    }
}
extension NewsItem: Hashable {
    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.title2 == rhs.title2 &&
            lhs.url == rhs.url &&
            lhs.redirectUrl == rhs.redirectUrl &&
            lhs.textUrl == rhs.textUrl &&
            lhs.onlineNum == rhs.onlineNum &&
            lhs.closedStatus == rhs.closedStatus &&
            lhs.views == rhs.views &&
            lhs.sharedCnt == rhs.sharedCnt &&
            lhs.timestamp == rhs.timestamp &&
            lhs.comments == rhs.comments &&
            lhs.category == rhs.category &&
            lhs.commentStatus == rhs.commentStatus &&
            lhs.moderationStatus == rhs.moderationStatus &&
            lhs.date == rhs.date &&
            lhs.datePublished == rhs.datePublished &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.hash == rhs.hash &&
            lhs.text?.count == rhs.text?.count &&
            lhs.textHtml?.count == rhs.textHtml?.count &&
            lhs.shortText?.count == rhs.shortText?.count &&
            lhs.sourceName?.count == rhs.sourceName?.count &&
            lhs.displayType == rhs.displayType &&
            lhs.image?.outer?.id == rhs.image?.outer?.id &&
            lhs.image?.outer?.title?.count == rhs.image?.outer?.title?.count &&
            lhs.image?.outer?.author?.count == rhs.image?.outer?.author?.count &&
            lhs.image?.outer?.thumb == rhs.image?.outer?.thumb &&
            lhs.headItem?.id == rhs.headItem?.id &&
            lhs.textType == rhs.textType &&
            lhs.textItems?.count == rhs.textItems?.count &&
            lhs.extraText?.count == rhs.extraText?.count &&
            lhs.binds?.count == rhs.binds?.count &&
            lhs.storyItems?.count == rhs.storyItems?.count &&
            lhs.tags?.count == rhs.tags?.count
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(title2)
        hasher.combine(url)
        hasher.combine(redirectUrl)
        hasher.combine(textUrl)
        hasher.combine(onlineNum)
        hasher.combine(closedStatus)
        hasher.combine(views)
        hasher.combine(sharedCnt)
        hasher.combine(timestamp)
        hasher.combine(comments)
        hasher.combine(category)
        hasher.combine(commentStatus)
        hasher.combine(moderationStatus)
        hasher.combine(date)
        hasher.combine(datePublished)
        hasher.combine(dateCreated)
        hasher.combine(hash)
        hasher.combine(text?.count)
        hasher.combine(textHtml?.count)
        hasher.combine(shortText?.count)
        hasher.combine(sourceName?.count)
        hasher.combine(displayType)
        hasher.combine(image?.outer?.id)
        hasher.combine(image?.outer?.title?.count)
        hasher.combine(image?.outer?.author?.count)
        hasher.combine(image?.outer?.thumb)
        hasher.combine(headItem?.id)
        hasher.combine(textType)
        hasher.combine(textItems?.count)
        hasher.combine(extraText?.count)
        hasher.combine(binds?.count)
        hasher.combine(storyItems?.count)
        hasher.combine(tags?.count)
    }
}
extension NewsItem {
    struct NewsImage: Decodable, Hashable {
        let outer: ImageItem?
        let inner: ImageItem?
        enum CodingKeys: String, CodingKey {
            case outer, inner
        }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            outer = try values.decodeIfPresent(ImageItem.self, forKey: .outer)
            inner = try values.decodeIfPresent(ImageItem.self, forKey: .inner)
        }
        static func == (lhs: NewsItem.NewsImage, rhs: NewsItem.NewsImage) -> Bool {
            return lhs.outer == rhs.outer &&
                lhs.inner == rhs.inner
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(outer)
            hasher.combine(inner)
        }
    }
    struct TextItem: Identifiable, Decodable, Hashable {
        var type: TextItemType
        var tag: HTMLTag?
        var content: String?
        let items: [TextItem]?
        let link: URL?
        let image: ImageItem?
        let newsItem: NewsItem?
        let embed: Embed?
        let layoutType: Media.Layout?
        let style: [HTMLStyle]?
        var id: String
        
        enum CodingKeys: String, CodingKey {
            case id, type, tag, content, items, image, newsItem="news_item", embed, media, style
            case layoutType="layout_type"
            case link="href"
        }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            type = try values.decode(TextItemType.self, forKey: .type)
            content = try values.decodeIfPresent(String.self, forKey: .content)
            do {
                tag = try values.decodeIfPresent(HTMLTag.self, forKey: .tag)
            //} catch DecodingError.keyNotFound(let key, let context) {
            } catch {// DecodingError.keyNotFound
                tag = HTMLTag.unk
            }
            items = try values.decodeIfPresent([TextItem].self, forKey: .items)
            link = try values.decodeIfPresent(URL.self, forKey: .link)
            image = try values.decodeIfPresent(ImageItem.self, forKey: .image)
            newsItem = try values.decodeIfPresent(NewsItem.self, forKey: .newsItem)
            embed = try values.decodeIfPresent(Embed.self, forKey: .embed)
            layoutType = try values.decodeIfPresent(Media.Layout.self, forKey: .layoutType)
            style = try values.decodeIfPresent([HTMLStyle].self, forKey: .style)
            do {
                id = try String(values.decodeIfPresent(Int.self, forKey: .id) ?? 0)
            } catch DecodingError.typeMismatch {
                id = try values.decodeIfPresent(String.self, forKey: .id) ?? "0"
            }
            if image != nil {
                id = "\(image!.id)"
            }
            if id == "0" || id.isEmpty {
                id = UUID().uuidString
            }
        }
        init(id: String, type: TextItemType, tag: HTMLTag? = nil, content: String? = nil, items: [TextItem]? = nil, link: URL? = nil, image: ImageItem? = nil, newsItem: NewsItem? = nil, embed: Embed? = nil, layoutType: Media.Layout? = nil, style: [HTMLStyle]? = nil) {
            self.id = id
            self.type = type
            self.tag = tag
            self.content = content
            self.items = items
            self.link = link
            self.image = image
            self.newsItem = newsItem
            self.embed = embed
            self.layoutType = layoutType
            self.style = style
        }
        static func == (lhs: TextItem, rhs: TextItem) -> Bool {
            return lhs.type == rhs.type &&
                lhs.tag == rhs.tag &&
                lhs.content?.count == rhs.content?.count &&
                lhs.items?.count == rhs.items?.count &&
                lhs.link == rhs.link &&
                lhs.image?.id == rhs.image?.id &&
                lhs.image?.title == rhs.image?.title &&
                lhs.image?.author == rhs.image?.author &&
                lhs.image?.thumb == rhs.image?.thumb &&
                lhs.newsItem?.id == rhs.newsItem?.id &&
                lhs.newsItem?.title.count == rhs.newsItem?.title.count &&
                lhs.embed?.id == rhs.embed?.id &&
                lhs.embed?.source == rhs.embed?.source &&
                lhs.embed?.url == rhs.embed?.url &&
                lhs.embed?.path?.thumb == rhs.embed?.path?.thumb &&
                lhs.embed?.path?.sd == rhs.embed?.path?.sd &&
                lhs.embed?.title?.count == rhs.embed?.title?.count &&
                lhs.embed?.name == rhs.embed?.name &&
                lhs.embed?.sensitive == rhs.embed?.sensitive &&
                lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(tag)
            hasher.combine(content?.count)
            hasher.combine(items?.count)
            hasher.combine(link)
            hasher.combine(image?.id)
            hasher.combine(image?.title)
            hasher.combine(image?.author)
            hasher.combine(image?.thumb)
            hasher.combine(newsItem?.id)
            hasher.combine(newsItem?.title.count)
            hasher.combine(embed?.id)
            hasher.combine(embed?.source)
            hasher.combine(embed?.url)
            hasher.combine(embed?.path?.thumb)
            hasher.combine(embed?.path?.sd)
            hasher.combine(embed?.title?.count)
            hasher.combine(embed?.name)
            hasher.combine(embed?.sensitive)
            hasher.combine(id)
        }
        func getTextItemURL() -> URL? {
            if type == .newsItem {
                return newsItem?.url
            } else if type == .embed {
                return embed?.url
            } else if let link = self.link {
                return link
            }
            
            return nil
        }
    }
    struct HeadItem: Identifiable, Decodable, Hashable {
        let id = UUID().uuidString
        let layoutType: Media.Layout?
        let items: [TextItem]?
        
        enum CodingKeys: String, CodingKey {
            case id, items
            case layoutType="layout_type"
        }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            items = try values.decodeIfPresent([TextItem].self, forKey: .items)
            layoutType = try values.decodeIfPresent(Media.Layout.self, forKey: .layoutType)
        }
        static func == (lhs: HeadItem, rhs: HeadItem) -> Bool {
            return lhs.id == rhs.id &&
                lhs.layoutType == rhs.layoutType &&
                lhs.items?.count == rhs.items?.count
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(layoutType)
            hasher.combine(items?.count)
        }
    }
    enum TextType: String, Decodable {
        case text = "text"
        case html = "html"
        case parsed = "parsed"
    }
    enum TextItemType: String, Decodable {
        case text, image, gallery, link, embed, list, quote, newsItem="news_item", unk
    }
    enum ClosedStatus: Int, Decodable {
        case opened=0, paid=1, archive=2
    }
}
extension TextItem {
    func isSensitive() -> Bool {
        if type == .image {
            guard let image = image else { return false }
            return image.sensitive != nil
        }
        return false
    }
}
extension TextItem {
    // MARK: For image init
    init(image: ImageItem) {
        self.id = image.id
        self.type = .image
        self.image = image
        
        self.tag = nil
        self.content = nil
        self.items = nil
        self.link = nil
        self.newsItem = nil
        self.embed = nil
        self.layoutType = nil
        self.style = nil
    }
}
struct NewsItemText: Decodable {
    var text, textHtml: String?//closedShort, closedText,
    var textUrl: URL?
    var textItems: [TextItem]?
    var textType: NewsItem.TextType?
    enum CodingKeys: String, CodingKey {
        case text, textHtml="text_html", textItems="text_items", textUrl="text_url", textType="text_type"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        textHtml = try values.decodeIfPresent(String.self, forKey: .textHtml)
        do {
            textItems = try values.decodeIfPresent([TextItem].self, forKey: .textItems)
        } catch {}
        textUrl = try values.decodeIfPresent(URL.self, forKey: .textUrl)
        textType = try values.decodeIfPresent(NewsItem.TextType.self, forKey: .textType)
    }
}
typealias NewsHeadItem = NewsItem.HeadItem
typealias TextItem = NewsItem.TextItem
typealias TextItemType = NewsItem.TextItemType
typealias NewsImage = NewsItem.NewsImage
typealias NewsClosedStatus = NewsItem.ClosedStatus
enum HTMLTag: String, Decodable {
    case text, img, blockquote, iframe, ul, ol, script, style, paragraph="p", link="a", block="div", lineBreak="br", horizontalLine="hr", listItem="li", unk="unknown"
}
