//
//  Style.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 11/8/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct HTMLStyle {
    let width: Int?
    let unit: Unit?
}
extension HTMLStyle: Decodable {
    enum CodingKeys: String, CodingKey {
        case width, unit
    }
    enum Unit: String, Decodable {
        case px, percent
    }
}
