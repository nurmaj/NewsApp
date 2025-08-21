//
//  PreferenceView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 24/8/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//  See https://stackoverflow.com/questions/64452647/how-we-can-get-and-read-size-of-a-text-with-geometryreader-in-swiftui

import SwiftUI

// 1. First create a custom PreferenceKey for the view size
struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
// 2. Create a view which will calculate its size and assign it to the ViewSizeKey:
struct ViewGeometry: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewSizeKey.self, value: geometry.size)
        }
    }
}
struct SizeModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: ViewSizeKey.self, value: geometry.size)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}
