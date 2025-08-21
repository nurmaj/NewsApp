//
//  FooterView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 18/3/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct FooterView: View {
    private var fetchItems: () -> Void
    @State
    var bottomReached = false
    init(fetchClosure: @escaping () -> Void) {
        fetchItems = fetchClosure
    }
    var body: some View {
        ZStack {
            Spacer(minLength: 36)
        }
        .frame(maxWidth: .infinity)
        .overlay(bottomReached ?
                     ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("GreyDark")))
                        .scaleEffect(1.2)
                 : nil)
        .onAppear {
            self.bottomReached = true
            fetchItems()
        }
        .onDisappear {
            self.bottomReached = false
        }
    }
}
