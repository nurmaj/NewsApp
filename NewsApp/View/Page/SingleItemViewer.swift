//
//  ItemViewer.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 2/9/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct SingleItemViewer: View {
    @Environment(\.presentationMode) var presentation
    let imageItem: ImageItem
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                ZStack {
                    AsyncImage(url: imageItem.getHd(), placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                    }, failure: {
                        Spacer()
                    })
                    .aspectRatio(contentMode: .fit)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .overlay(
            // Close Button
            Button(action: {
                //withAnimation() {
                withAnimation(.easeInOut(duration: 2)) {
                    presentation.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(Font.title.weight(.ultraLight))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.vertical)
            }
            , alignment: .topLeading
        )
        .background(Color.black.ignoresSafeArea())
    }
}
struct SingleItemViewer_Previews: PreviewProvider {
    static var previews: some View {
        SingleItemViewer(imageItem: ImageItem(id: "1", title: nil, author: nil, name: nil, thumb: URL(string: "https://static.newsapp.media/av/1/pbe3cc.200.jpg")!, sd: nil, hd: nil, sensitive: nil, width: nil, height: nil))
    }
}
