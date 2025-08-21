//
//  Constants.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 13/8/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct API {
    static let appNameLatin = "NewsApp"
    static let supportEmail = "nurma131@gmail.com"
    static let appIdForRemote = "media.newsapp"
    struct Endpoint {
        static let projectHost: String = "newsapp.media"
        static let baseUrl: String = "https://newsapp.media/api"
        static let projectUrl = "https://newsapp.media"
        static let analyticUrl = "https://analytics.newsapp.media"
        static let project_search_url = "https://newsapp.media/search/?query="
        static let adUrl = "https://newsapp.media/ad"
        static let appStoreDeveloperUrl = "https://apps.apple.com/ru/developer/id1136576704"
        static func generateBoundary() -> String {
            return "FormBoundary\(UUID().uuidString)"
        }
    }
    struct Device {
        static func getInfo() -> [String: String] {
            var info: [String: String] = ["manufacturer": "Apple", "device": UIDevice.current.model, "model": UIDevice.current.modelName,
                                          "version": UIDevice.current.systemVersion, "date": Util().currentDatetime]
            if let locale = Locale.preferredLanguages.first {
                info["locale"] = locale
            }
            if let timezone = TimeZone.current.abbreviation() {
                info["timezone"] = timezone
            }
            return info
        }
    }
    struct SharedPage {
        func page(_ page: Page, section: Section, host: String = API.Endpoint.projectHost) -> String {
            return "https://" + host + page.rawValue + "/?from=" + API.appIdForRemote + (section != .none ? "&"+section.rawValue : "")
        }
        enum Page: String {
            case helpCenter="/help", policy="/policy"
        }
        enum Section: String {
            case home="home", whyAccount="account#see-why", none="#"
        }
    }
    enum ShareType: String {
        case newsItem="news_item", pollItem="poll_item", webPage="web_page", tagPage="tag_page", searchPage="search_page", image="image", video="video"
    }
    enum ActionType {
        case add, edit, delete
    }
    struct Subscription {
        static let defaultBuyOrSubscribe = "embed&pack"
        static let defaultSuccessUrl = "ismobile=1&bank=ok"
        static let defaultFailureUrl = "ismobile=1&bank=no"
    }
}
