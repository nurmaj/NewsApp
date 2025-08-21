//
//  MenuItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct MenuItem: Identifiable {
    let name: String
    let systemIcName: String?
    let customIcName: String?
    let detailKey: MenuDetailKey?
    var id: String { name }
    var urlStr: String?
    var action: (() -> ())?
}
enum MenuDetailKey {
    case notification, settings, about, settingsTab
}
