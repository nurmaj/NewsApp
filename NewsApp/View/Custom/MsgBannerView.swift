//
//  MsgBannerView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 15/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct MsgBannerView: View {
    @Binding
    var message: String
    @Binding
    var iconName: String
    @Binding
    var show: Bool
    var appearDuration: Double = 3
    var paddingBottom: CGFloat = .zero
    var body: some View {
        HStack(spacing: 0) {
            if !iconName.isEmpty {
                Image(systemName: iconName)
                    .font(.title2)
            }
            Text(LocalizedStringKey(message))
                .font(.system(size: 14))
                .padding(.leading, 10)
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("BlackGrey"))
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
                .cornerRadius(12)
        )
        .padding(.bottom, paddingBottom)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + appearDuration) {
                withAnimation {
                    self.show = false
                    self.message = ""
                    self.iconName = ""
                }
            }
        }
        .transition(.move(edge: .bottom))
    }
}

struct MsgBannerView_Previews: PreviewProvider {
    static var previews: some View {
        MsgBannerView(message: .constant("Не удалось обновить ленту"), iconName: .constant("exclamationmark.circle"), show: .constant(true))
    }
}
