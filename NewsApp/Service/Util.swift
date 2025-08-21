//
//  Util.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 7/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct Util {
    var currentYear: String {
        "\(Calendar.current.component(.year, from: Date()))"
    }
    var currentDatetime: String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return df.string(from: date)
    }
}
