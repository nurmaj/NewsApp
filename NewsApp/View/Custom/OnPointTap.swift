//
//  OnPointTap.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 10/3/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct OnPointTap: ViewModifier {
    let response: (CGPoint) -> Void
    @State
    private var location: CGPoint = .zero
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                response(location)
            }
    }
}
extension View {
    func onPointTapGesture(_ handler: @escaping (CGPoint) -> Void) -> some View {
        self.modifier(OnPointTap(response: handler))
    }
}
