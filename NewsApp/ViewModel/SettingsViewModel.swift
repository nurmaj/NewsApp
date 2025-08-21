//
//  SettingsViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 5/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
class SettingsViewModel: ObservableObject {
    @Published
    var dataSaver: Bool = Preference.bool(.dataSaver)
    @Published
    var tabItems = [TabItem]()
    @Published
    var launchableTabItems = [TabItem]()
    @Published
    var launchTabItem: TabItem?
    @Published
    var messageText = ""
    @Published
    var showMessage = false
    private var appConfig = AppConfig()
    
    init() {
        self.tabItems = appConfig.getAppTabItems()
        self.launchTabItem = appConfig.getLaunchTabItem()
        for tabItem in self.tabItems {
            if tabItem.launchable {
                self.launchableTabItems.append(tabItem)
            }
        }
    }
    func changeDataSaverState(_ newState: Bool) {
        Preference.set(newState, key: .dataSaver)
    }
    func setLaunchTabItem(_ tab: TabItem) {
        self.launchTabItem = tab
        Preference.set(tab.key, key: .launchTabItemKey)
    }
    func showSettingsMsgBanner(msg: String) {
        self.messageText = msg
        self.showMessage = true
    }
}
