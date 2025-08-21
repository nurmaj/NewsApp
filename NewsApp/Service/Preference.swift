//
//  Preference.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 7/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct Preference {
    static func string(_ key: AppPreferenceKey, strKey: String? = nil) -> String? {
        return Default.standard.string(forKey: getKeyName(key, strKey))
    }
    static func bool(_ key: AppPreferenceKey, strKey: String? = nil, defaultIfNil: Bool = false) -> Bool {
        guard let boolVal = Default.standard.value(forKey: getKeyName(key, strKey)) else {
            return defaultIfNil
        }
        return "\(boolVal)" == "1"
    }
    static func int(_ key: AppPreferenceKey, strKey: String? = nil) -> Int {
        return Default.standard.integer(forKey: getKeyName(key, strKey))
    }
    static func array(_ key: AppPreferenceKey, strKey: String? = nil) -> [String]? {
        return Default.standard.array(forKey: getKeyName(key, strKey)) as? [String]
    }
    static func data(_ key: AppPreferenceKey, strKey: String? = nil) -> Data? {
        return Default.standard.data(forKey: getKeyName(key, strKey))
    }
    static func set(_ value: Any?, key: AppPreferenceKey, strKey: String? = nil) {
        //print("PREF SET VALUE: \(value ?? "Nil") forKey: \(key.rawValue) for strKey: \(strKey ?? "Nil") With final name: \(getKeyName(key, strKey))")
        Default.standard
            .set(value, forKey: getKeyName(key, strKey))
    }
    private static func getKeyName(_ key: AppPreferenceKey, _ strKey: String?) -> String {
        if let strKeyAsPrefix = strKey, key != .strKeyname {
            return "\(key.rawValue)\(strKeyAsPrefix)"
        }
        return strKey ?? key.rawValue
    }
    private struct Default {
        static let standard = UserDefaults.standard
    }
}
enum AppPreferenceKey: String {
    case mainNotification="main_notification_pref", dataSaver="data_saver_pref"
    case deviceInfoId="device_info_id_pref", deviceInfoToken="device_info_token_pref"
    case configSetKey="config_set_key_pref", remoteTabItems="remote_tab_items_pref", launchTabItemKey="launch_tab_item_key_pref", subscriptionConfig="subscription_config_pref"
    case fcmToken="firebase_cloud_messaging_token_pref"
    case strKeyname="str_key_name"
    /*Poll*/
    case votedOptionID="voted_option_id_pref"
    case votedPollPrefix="voted_poll_"
}
