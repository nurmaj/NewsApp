//
//  ActiveCover.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 23/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
enum ActiveCover: Identifiable {
    //videoPlayer, fullscreenAd,
    case webView, itemViewer, menuDetail
    var id: Int {
        hashValue
    }
}
