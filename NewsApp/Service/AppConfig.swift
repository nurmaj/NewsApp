//
//  AppConfig.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 2/2/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct AppConfig {
    struct DefaultValues {
        static let projectAspectRatio: CGFloat = 16 / 9 //
        static let tokenLength = 221
        static let appNavBarHeight: CGFloat = 40
        //static let CAROUSEL_THRESHOLD: CGFloat = 40
        static let defaultRefreshThreshold: CGFloat = 100//68
        static let primitiveLinkDateWidth: CGFloat = 72
        static let ITEMS_PER_PAGE: Int = 10
        static let bottomLoadMaxNumber: Int = 20
        static let MAIN_PUSH_NOT_TOPIC = "p0_topnews_ios"
    }
    struct GestureValues {
        static let BACK_VIEW_OFFSET_X: CGFloat = -100
        static let MAX_SCALE_NUM: CGFloat = 5
        static let MIN_TMP_SCALE_NUM: CGFloat = 0.8
        static let DRAG_OFFSET_PADDING: CGFloat = 60
        static let DRAG_DISMISS_OFFSET: CGFloat = 180
        static let BACK_PUSH_THRESHOLD: CGFloat = 40
    }
    struct MediaValues {
        static let PLAYER_MINIMIZE_TIME: Double = 3.0
        static let PLAYER_PROGRESS_MIN_WIDTH: CGFloat = 8
        static let BLACK_BG_OPACITY: Double = 0.35
    }
    struct CarouselValues {
        static let SWITCH_THRESHOLD: CGFloat = 50
        static let spacing: CGFloat = 10
        static let visiblePartItemWidth: CGFloat = 20
        /*static let spacing: CGFloat = 16
        static let visiblePartItemWidth: CGFloat = 32*/
        static let padding: CGFloat = 40
        static let decreaseOfNonActive: CGFloat = .zero
    }
    struct DefaultTab {
        static let MENU_TAB_ITEM = TabItem(key: "menu", name: "Меню", icon: IconItem(name: "menu", filled: nil), queue: 4)
        static let DEFAULT_FEED_LAYOUT = FeedLayout.large
        static let DEFAULT_TAB_ITEM_KEY = "last"
        static let TOP_ITEM_ID_FOR_SCROLL = "TOP_ITEM_ID_FOR_SCROLL"
        static let items: [TabItem] = [
            .init(key: "last", name: "Последнее", icon: IconItem(name: "last", filled: nil), canScrollLoad: true, queue: 0, launchable: true),
            .init(key: "real_time", name: "Сейчас читают", icon: IconItem(name: "real_time", filled: nil), queue: 1, layoutType: .small, launchable: true),
            .init(key: "top", name: "Популярное", icon: IconItem(name: "top", filled: nil), queue: 2, showViewNum: true, launchable: true),
            .init(key: "ky_feed", name: "Кыргызча", icon: IconItem(name: "ky", filled: nil), canScrollLoad: true, queue: 3, launchable: true),
        ]
    }
}
typealias CarouselConfig = AppConfig.CarouselValues
typealias DefaultAppConfig = AppConfig.DefaultValues
typealias DefaultAppTabConfig = AppConfig.DefaultTab
extension AppConfig {
    func getRemoteTabItems() -> [TabItem]? {
        guard let tabItemsData = Preference.data(.remoteTabItems) else {
            return nil
        }
        guard var tabItems = try? JSONDecoder().decode([TabItem].self, from: tabItemsData) else {
            return nil
        }
        if let tabLifeTimeIndex = tabItems.firstIndex(where: { $0.lifetime != nil }) {
            if let tabLifeTime = tabItems[tabLifeTimeIndex].lifetime, tabLifeTime.isoDateExpired() {
                tabItems.remove(at: tabLifeTimeIndex)
                putRemoteTabItems(tabItems)
            }
        }
        if tabItems.count > 4 {
            return Array(tabItems[0...3])
        }
        return tabItems
    }
    func putRemoteTabItems(_ tabs: [TabItem]?) {
        Preference.set(sortTabItems(tabs).toEncodedData(), key: .remoteTabItems)
    }
    func sortTabItems(_ tabs: [TabItem]?) -> [TabItem]? {
        if let tabItems = tabs, tabItems.count > 0 {
            var queuedItems = [TabItem]()
            for tabItem in tabItems {
                if let lifeTime = tabItem.lifetime, lifeTime.isoDateExpired() {
                    continue
                }
                queuedItems.append(tabItem)
            }
            return queuedItems.sorted(by: { $0.queue < $1.queue })
        }
        return nil
    }
    func getAppTabItems() -> [TabItem] {
        var tabs: [TabItem] = self.getRemoteTabItems() ?? DefaultTab.items
        tabs.append(DefaultTab.MENU_TAB_ITEM)
        return tabs
    }
    func getLaunchTabItem() -> TabItem? {
        if let prefLaunchTabItem = self.getAppTabItems().first(where: { $0.key == Preference.string(.launchTabItemKey) }) {
            return prefLaunchTabItem
        }
        return self.getAppTabItems().first
    }
    func getTabLabelByKey(key: String?) -> String? {
        // MARK: When Nil return launch tab name
        if key == nil {
            return self.getAppTabItems().first(where: { $0.key == self.getLaunchTabItem()?.key })?.name
        }
        return self.getAppTabItems().first(where: { $0.key == key })?.name
    }
}
extension AppConfig {
    func getSubscriptionConfig() -> SubscriptionConfig? {
        guard let jsonData = Preference.data(.subscriptionConfig) else {
            return nil
        }
        return try? JSONDecoder().decode(SubscriptionConfig.self, from: jsonData)
    }
}
