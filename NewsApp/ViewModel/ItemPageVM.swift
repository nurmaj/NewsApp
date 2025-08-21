//
//  ItemPageVM.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/3/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
class ItemPageVM: ObservableObject {
    /*@Published
    var selectedItemId: String = ""*/
    @Published
    var currentIndex = Int.zero
    @Published
    var currentImageItem: ImageItem?
    @Published
    var gesturesDisabled = false
    @Published
    var offsetY = CGFloat.zero
    @Published
    var bgOpacity: CGFloat = 1
    @Published
    var contentSize = CGSize.zero
    @Published
    var barMinimized = false
    @Published
    var bottomBarHidden = false
    
    func getURLStr(textItem: TextItem) -> String {
        if let currentImageItem = self.currentImageItem {
            let imageURLStr = Preference.bool(.dataSaver) ? currentImageItem.sd?.absoluteString : currentImageItem.hd?.absoluteString
            return imageURLStr ?? currentImageItem.thumb.absoluteString
        } else if let textItemUrl = textItem.getTextItemURL() {
            return textItemUrl.absoluteString
        }
        return ""
    }
}
