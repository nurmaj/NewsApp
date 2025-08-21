//
//  AppAdViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
protocol AppAdViewModel {
    func loadAd(targets: [AdTarget], pageKey: String, newsItemId: String)
}
