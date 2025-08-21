//
//  RefreshProgressView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 8/1/23.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct RefreshProgressView: View {
    @Binding
    var showRefresh: Bool
    var body: some View {
        if showRefresh {
            ZStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            //.animation(.easeOut)
            //.animation(.interactiveSpring(), value: feedVM.pullRefreshing)
            //.transition(.scale(scale: 1, anchor: .top))
        }
    }
}

struct RefreshProgressView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshProgressView(showRefresh: .constant(false))
    }
}
