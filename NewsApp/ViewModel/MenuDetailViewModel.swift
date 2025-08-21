//
//  MenuDetailViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

class MenuDetailViewModel: ObservableObject {
    @Published
    var menuItem: MenuItem
    init(menuItem: MenuItem) {
        self.menuItem = menuItem
    }
}
