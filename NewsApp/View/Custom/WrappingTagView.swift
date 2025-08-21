//
//  WrappingTagView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 2/9/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct WrappingTagView: View {
    let tags: [PrimitiveItem]
    let onTagTap: (PrimitiveItem) -> Void
    
    @State
    private var totalHeight
          = CGFloat.zero       // << variant for ScrollView/List
    //    = CGFloat.infinity   // << variant for VStack
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(minHeight: 25)
        .frame(height: totalHeight)// << variant for ScrollView/List
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.tags, id: \.self) { tag in
                self.item(for: tag)
                    .contentShape(Rectangle())
                    .padding([.horizontal, .vertical], 4)
                    .zIndex(1)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = .zero
                            height -= d.height
                        }
                        let result = width
                        if tag == self.tags.last! {
                            width = .zero //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if tag == self.tags.last! {
                            height = .zero // last item
                        }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }

    private func item(for tagItem: PrimitiveItem) -> some View {
        Text("#\(tagItem.title)")
            .font(.system(size: 14))
            .foregroundColor(Color("BlueTint"))
            .onTapGesture {
                self.onTagTap(tagItem)
            }
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = binding.wrappedValue > .zero ? binding.wrappedValue : rect.size.height
            }
            return .clear
        }
    }
}
