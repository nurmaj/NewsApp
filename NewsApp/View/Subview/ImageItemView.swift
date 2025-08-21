//
//  ImageItemView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 1/9/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ImageItemView: View {
    let image: ImageItem
    let newsItemId: String
    let frameWidth: CGFloat
    let presentImageView: ([TextItem], String) -> Void
    var disableViewer = false
    private var imageTextItem: TextItem {
        TextItem(image: image)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            NewsTextObjectContent(textItem: imageTextItem, parentItemId: newsItemId, contentSize: newsImageSize(), presentNewsItem: { _ in }, presentDetailMedia: { _ in })
                //CGSize(width: widthWithPadding, height: newsImageHeight())
                .overlay(ImageCaption(caption: image.title, author: image.author), alignment: .bottomTrailing)
                .simultaneousGesture( !disableViewer ? TapGesture().onEnded(onNewsImageTap) : nil)
            CustomDivider()
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 10)
    }
    private func newsImageSize() -> CGSize {
        var contentSize = CGSize(width: frameWidth - 20, height: (frameWidth - 20) / DefaultAppConfig.projectAspectRatio)
        if let width = image.width {
            guard let height = image.height else {
                return contentSize
            }
            if height > width {
                let aspectRatio = CGFloat(height) / CGFloat(width)
                contentSize.width = contentSize.width / aspectRatio
                contentSize.height = contentSize.width * aspectRatio
            } else {
                contentSize.height = contentSize.width / (CGFloat(width) / CGFloat(height))
            }
        }
        return contentSize
    }
    private func onNewsImageTap() {
        self.presentImageView([imageTextItem], image.id)
    }
}

struct ImageCaption: View {
    let caption: String?
    let author: String?
    var body: some View {
        if self.caption != nil || self.author != nil {
            VStack(alignment: .trailing, spacing: 2) {
                if let caption = caption {
                    Text(caption)
                        .font(.caption)
                }
                if let author = author {
                    Text(author)
                        .font(.caption2)
                }
            }
            .foregroundColor(Color.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Rectangle()
                    .fill(Color("BlackGrey").opacity(0.7))
            )
        }
    }
}

struct ImageItemView_Previews: PreviewProvider {
    static var previews: some View {
        ImageItemView(image: ImageItem(id: "0_0", title: "Aasdas asdasd", author: "// AKSjj", name: nil, thumb: URL(string: "https://st-0.newsapp.media/st_gallery/93/1206593.2889ad5120e8703b667320747984bd85.jpg")!, sd: nil, hd: nil, sensitive: nil, width: nil, height: nil), newsItemId: "0", frameWidth: 390, presentImageView: { _, _ in })
    }
}
