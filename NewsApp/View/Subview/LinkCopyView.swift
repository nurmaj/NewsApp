//
//  LinkCopyView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/5/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct LinkCopyView: View {
    let urlToCopy: URL
    var body: some View {
        ZStack {
            Color("GreyBg")
                //.border(Color("GreyTint"), width: 1)
            HStack(spacing:0) {
                Text(urlToCopy.absoluteString)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .foregroundColor(Color("GreyDark"))
                Button(action: {
                    
                }) {
                    Text("read_on_website")
                        .font(.system(size: 12, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundColor(Color("BlackTint"))
                }
                .padding(.horizontal, 6)
                .frame(minHeight: 0, maxHeight: .infinity)
                .background(Color("WhiteBlackBg"))
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(height: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color("GreyTint"), lineWidth: 1)
        )
        //.edgesIgnoringSafeArea(.all)
    }
}

struct LinkCopyView_Previews: PreviewProvider {
    static var previews: some View {
        LinkCopyView(urlToCopy: URL(string: "https://newsapp.media?from=newsapp-ios")!)
            //.preferredColorScheme(.dark)
    }
}
