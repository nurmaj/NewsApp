//
//  BackButtonView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 13/7/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct BackButtonView: View {
    var backText: String?
    var closeIconOnly = false
    var accentColor: Color = Color("GreyTint")
    let onCloseTap: () -> Void
    var body: some View {
        Button(action: onCloseTap) {
            HStack(spacing: 2) {
                Image(systemName: closeIconOnly ? "xmark" : "chevron.left")
                    .imageScale(.large)
                if !closeIconOnly {
                    Text(LocalizedStringKey(backText ?? "back"))
                        .font(.system(size: 16))
                }
            }
            .accentColor(accentColor)
        }
    }
}

struct BackButtonView_Previews: PreviewProvider {
    static var previews: some View {
        BackButtonView(onCloseTap: {})
    }
}
