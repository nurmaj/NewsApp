//
//  ItemDetail.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 3/5/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ItemDetail: View {
    var items: [TextItem]
    @Binding
    var selectedItemId: String
    let parentItemId: String
    let frameSize: CGSize
    let onDismissTap: () -> Void
    var body: some View {
        ZStack {
            ScrollView(.init()) {
                TabView(selection: $selectedItemId) {
                    ForEach(items) { item in
                        ItemDetailPage(item: item, frameSize: frameSize) { direction in
                            changePage(to: direction, from: item)
                        }
                        .frame(width: frameSize.width)
                        .tag(item.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(width: frameSize.width + CarouselConfig.SWITCH_THRESHOLD)
                .frame(maxHeight: .infinity)
                .overlay(
                    // Close Button
                    HStack(spacing: 0) {
                        Spacer()
                        Button(action: {
                            dismissDetailView()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.top, safeEdges?.top ?? 10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .frame(width: frameSize.width)
                    , alignment: .topLeading )
            }
        }
        .frame(maxHeight: .infinity)
        .ignoresSafeArea()
        .background(
            Color.black
                .edgesIgnoringSafeArea(.all)
        )
    }
    func changePage(to direction: MoveDirection, from item: TextItem) {
        if direction == .right {
            guard let nextItem = items.nextEl(after: item, infinite: false) else { return }
            selectedItemId = nextItem.id
        } else if direction == .left {
            guard let prevItem = items.prevEl(before: item, infinite: false) else { return }
            selectedItemId = prevItem.id
        }
    }
    private func dismissDetailView() {
        withAnimation(.easeInOut) {
            onDismissTap()
        }
    }
}

struct ItemDetailPage: View {
    let item: TextItem
    let frameSize: CGSize
    let onPageChanged: (MoveDirection) -> ()
    @StateObject
    private var detailPageVM = ItemDetailPageVM()
    var body: some View {
        ZStack {
            if let imageItem = item.image, item.type == .image {
                AsyncImage(
                    url: imageItem.hd ?? imageItem.thumb,
                    placeholder: {
                        AsyncImage(
                            url: imageItem.sd ?? imageItem.thumb,
                            placeholder: {
                                Spacer()
                            }, failure:{Spacer()}
                        )
                    }, failure: { Spacer() }
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: frameSize.width)
                .background(
                    GeometryReader { geo in
                        Color.clear
                    }
                )
            }
        }
    }
}

struct ItemDetail_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetail(items: [TextItem(id: "1", type: .image)], selectedItemId: .constant("1"), parentItemId: "", frameSize: CGSize.zero, onDismissTap: {})
    }
}
