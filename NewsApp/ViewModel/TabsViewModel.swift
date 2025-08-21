//
//  TabsViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

class TabsViewModel: ObservableObject {
    @Published
    var tabs: [TabItem]
    @Published
    var selectedTab: String = ""
    @Published
    var fromPageItem: FromPage?
    @Published
    var sendDeviceState: NetworkingState = .inited
    @Published
    var scrollTarget: MoveDirection?
    /* Search feature properties */
    @Published
    var searchModeExpanded = false
    /**/
    private let appConfig = AppConfig()
    private var disposeBag = DisposeBag()
    @Published
    var detailedFeedItem: FeedItemDetail?
    @Published
    var updatedFeedItem: FeedItemDetail?
    @Published
    var loginViewItem: LoginViewItem?
    @Published
    var feedOffsetX = CGFloat.zero
    @Published
    var detailOffset = CGPoint.zero
    @Published
    var pushBackDisabled = false
    @Published
    var detailDismissActive = false
    @Published
    var isHorizontal = false
    
    init() {
        self.tabs = appConfig.getAppTabItems()
        self.selectedTab = appConfig.getLaunchTabItem()?.key ?? DefaultAppTabConfig.DEFAULT_TAB_ITEM_KEY
    }
    func sendDeviceInfo() {
        let apiRequest = APIRequest()
        if sendDeviceState == .processing {
            return
        }
        sendDeviceState = .processing
        let configKey = Preference.string(.configSetKey)
        apiRequest.sendDeviceInfo(deviceId: Preference.int(.deviceInfoId), deviceToken: Preference.string(.deviceInfoToken), configSetkey: configKey, extra: API.Device.getInfo())
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.sendDeviceState = .failed
                default:
                    self.sendDeviceState = .finished
                    break
                }
            }) { response in
                if response.success {
                    if let newDeviceToken = response.newToken, let newDeviceId = response.newDeviceId {
                        Preference.set(newDeviceToken, key: .deviceInfoToken)
                        Preference.set(newDeviceId, key: .deviceInfoId)
                    }
                }
                if let newConfig = response.config, newConfig.key != configKey {
                    self.appConfig.putRemoteTabItems(newConfig.tabItems)
                    
                    if let subsConf = newConfig.subscription {
                        Preference.set(subsConf.toEncodedData(), key: .subscriptionConfig)
                    }
                    Preference.set(newConfig.key, key: .configSetKey)
                }
            }
            .store(in: disposeBag)
    }
    func onTabReselect(direction: MoveDirection) {
        self.scrollTarget = direction
    }
    func resetDetailItem() {
        self.detailedFeedItem = nil
        self.fromPageItem = nil
        self.detailDismissActive = false
    }
    func setIsHorizontal(_ value: Bool) {
        self.isHorizontal = value
    }
    func getAnalyticsExtraParams(for tabItem: TabItem) -> [String: Any] {
        return appConfig.getLaunchTabItem()?.key == tabItem.key ? ["is_launch": true] : [:]
    }
}
