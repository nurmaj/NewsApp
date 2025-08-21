//
//  Item.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 25/2/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

protocol Item: Identifiable {
    var id: String { get }
    var title: String { get }
    var title2: String? { get }
    var date: String { get }
    var views: String? { get }
}
