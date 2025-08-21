//
//  FCMService.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 11/12/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
import FirebaseMessaging
import Combine

final class FCMService {
    static let shared = FCMService()
    func subscribeToTopicIfEnabled(_ name: String, pref: AppPreferenceKey) {
        if let _ = Preference.string(.fcmToken), Preference.bool(pref, defaultIfNil: true) {
            Messaging.messaging().subscribe(toTopic: name) { error in }
        } else {}
    }
    func subscribeToTopic(_ name: String) {
        Messaging.messaging().subscribe(toTopic: name) { _ in }
    }
    func unsubscribeFromTopic(_ name: String) {
        Messaging.messaging().unsubscribe(fromTopic: name)
    }
    func retrievePushNotItem(from info: [AnyHashable: Any], onReceive: @escaping (PushNotItem) -> Void) {
        do {
            if let newsItemJson = info[AppPushNotType.newsItem.rawValue] as? String {
                let newsItem = try JSONDecoder().decode(NewsItem.self, from: Data(newsItemJson.utf8))
                onReceive(PushNotItem(newsItem: newsItem))
            } else if let linkItemJson = info[AppPushNotType.linkItem.rawValue] as? String {
                let linkItem = try JSONDecoder().decode(PushLinkItem.self, from: Data(linkItemJson.utf8))
                onReceive(PushNotItem(linkItem: linkItem))
            }
        } catch {
            print("FCMService Error: \(error)")
        }
    }
}
