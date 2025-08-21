//
//  CarouselViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 2/9/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
class CarouselViewModel: ObservableObject {
    @Published
    var parentItemId: String
    @Published
    var items: [TextItem]
    // Viewer's properties
    /*@Published
    var showViewer = false*/
    /*@Published
    var selectedItem: TextItem?*/
    //var selectedItem: TextItem = TextItem(id: "0", type: .unk)
    @Published
    var selectedItemId: String// = ""
    @Published
    var selectedIndex = Int.zero
    @Published
    var dismiss = false
    /*@Published
    var contentSize: CGSize*/
    @Published
    var seeSensitiveContent: Bool = false
    /*@Published
    var selectedItemSensitive: Bool = false*/
    // MARK: DRAG Gesture States
    @Published
    var activeOffsetX = CGFloat.zero
    @Published
    var calcOffset = CGFloat.zero
    @Published
    var dragGestureEnded = false
    
    init(parentId: String, items: [TextItem]/*, contentWidth: CGFloat*/) {//, selectedItem: TextItem?, selectedItemId: String?
        self.parentItemId = parentId
        self.items = items
        //self.contentSize = CGSize(width: contentWidth, height: contentWidth / AppConfig.projectAspectRatio)
        self.selectedItemId = items.first?.id ?? ""
        //self.contentSize.height = contentWidth / AppConfig.projectAspectRatio
        /*self.selectedItem = selectedItem
        self.selectedItemId = selectedItemId ?? ""*/
    }
    func setSelectedItem(at index: Int) {
        if index < items.count {
            //self.selectedItem = items[index]
            let item = items[index]
            self.selectedItemId = item.id
            self.selectedIndex = index
        }
    }
    func getItemIndex(_ item: TextItem) -> Int {
        return items.firstIndex(of: item) ?? .zero
    }
    func canTapOnItem() -> Bool {
        return items[selectedIndex].type == .image
    }
    /*func itemSensitive(item: TextItem) -> Bool {
        if item.type == .image {
            guard let image = item.image else { return false }
            return image.sensitive != nil
        }
        return false
    }*/
}
