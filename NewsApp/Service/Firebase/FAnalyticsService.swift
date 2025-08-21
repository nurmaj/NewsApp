//
//  FAnalyticsService.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 12/12/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
import FirebaseAnalytics

final class FAnalyticsService {
    static let shared = FAnalyticsService()
    
    func sendLogEvent(id: String, title: String, type: String) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            //AnalyticsParameterItemID: "id-\(title)",
            AnalyticsParameterItemID: id,
            AnalyticsParameterItemName: title,
            AnalyticsParameterContentType: type,
        ])
    }
    
    func sendScreenView(_ name: String, className: String, extraParameters: [String: Any] = [:]) {
        var parameters = extraParameters
        parameters[AnalyticsParameterScreenName] = name
        parameters[AnalyticsParameterScreenClass] = className
        Analytics.logEvent(AnalyticsEventScreenView,
                           parameters: parameters)
    }
}
