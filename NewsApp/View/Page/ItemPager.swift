//
//  ItemPager.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 11/5/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ItemPager: View {
    let items: [TextItem]
    @Binding
    var selectedItemId: String
    let parentItemId: String
    let frameSize: CGSize
    
    let presentNewsItem: (NewsItem) -> Void
    let presentDetailMedia: (DetailMedia) -> Void
    
    let onDismissTap: () -> Void
    
    @Environment(\.isHorizontal)
    private var isHorizontal
    @GestureState
    private var translationYActive = false
    @StateObject
    var itemPagerVM = ItemPageVM()
    
    var body: some View {
        ScrollView(.init()) {
        //ZStack(alignment: .leading) {
            TabView(selection: $selectedItemId) {
                ForEach(items) { item in
                    PagerContent(selectedItemId: $selectedItemId, item: item, frameSize: frameSize, translationY: $itemPagerVM.offsetY, gesturesDisabled: $itemPagerVM.gesturesDisabled, currentIndex: $itemPagerVM.currentIndex, barMinimized: $itemPagerVM.barMinimized, bottomBarHidden: $itemPagerVM.bottomBarHidden, parentItemId: parentItemId, presentNewsItem: presentNewsItem, presentDetailMedia: presentDetailMedia/*, contentSize: $contentSize*/)
                        .tag(item.id)
                }
                .ignoresSafeArea()
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(width: getContentSize().width, height: getContentSize().height)
            .onChange(of: selectedItemId) { currentId in
                setIndexMatchSelectedItem(currentId)
            }
            .onChange(of: isHorizontal) { _ in
                calcContentSize()
                // MARK: Bug when orientation change, TabView resets to first index. Solution: reset back after delay
                if itemPagerVM.currentIndex > 0 {
                    let beforeIndex = itemPagerVM.currentIndex
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.selectedItemId = items[beforeIndex].id
                    }
                }
            }
            .simultaneousGesture( !itemPagerVM.gesturesDisabled ?
                DragGesture(minimumDistance: 20).updating($translationYActive) { (value, state, _) in
                    state = true
                }.onChanged { value in
                    itemPagerVM.offsetY = value.translation.height
                }.onEnded { value in
                    if abs(value.translation.height) >= AppConfig.GestureValues.DRAG_DISMISS_OFFSET {
                        dismissPager()
                        return
                    }
                } : nil
            )
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: translationYActive) { newActiveDrag in
            if !newActiveDrag {
                onDragCancelled()
            }
        }
        .onChange(of: itemPagerVM.offsetY) { newY in
            self.itemPagerVM.bgOpacity = newY.opacityProgress
        }
        .onAppear(perform: onPagerAppear)
        .onDisappear {
            UIScrollView.appearance().bounces = true
        }
        .background(
            Color.black
                .ignoresSafeArea()
                .opacity(itemPagerVM.bgOpacity)
        )
        .overlay(TopBar(currentIndex: $itemPagerVM.currentIndex, length: items.count, minimized: $itemPagerVM.barMinimized, dismissPager: dismissPager), alignment: .top)
        .overlay(!itemPagerVM.bottomBarHidden ? BottomBar(currentImageItem: $itemPagerVM.currentImageItem, minimized: $itemPagerVM.barMinimized) : nil, alignment: .bottom)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    private func onPagerAppear() {
        UIScrollView.appearance().bounces = false
        onDragCancelled()
        calcContentSize()
        setIndexMatchSelectedItem(selectedItemId)
    }
    private func setIndexMatchSelectedItem(_ currentId: String) {
        if let currentIndex = items.firstIndex(where: { $0.id == currentId }) {
            self.itemPagerVM.currentIndex = currentIndex
            let currentItem = items[currentIndex]
            self.changePagerStates(for: currentItem)
            self.setCurrentImageItem(at: currentIndex)
            FAnalyticsService.shared.sendScreenView(itemPagerVM.getURLStr(textItem: currentItem), className: String(describing: ItemPager.self))
        }
    }
    private func setCurrentImageItem(at index: Int) {
        withAnimation(.easeInOut) {
            if let currentImageItem = items[index].image {
                self.itemPagerVM.currentImageItem = currentImageItem
            } else {
                self.itemPagerVM.currentImageItem = nil
            }
        }
    }
    private func getS() -> String {
        return ""
    }
    private func changePagerStates(for item: TextItem) {
        if item.isSensitive() {
            self.itemPagerVM.gesturesDisabled = true
        } else if !item.isSensitive() && itemPagerVM.gesturesDisabled {
            self.itemPagerVM.gesturesDisabled = false
        }
        if item.type != .image || itemPagerVM.gesturesDisabled {
            self.itemPagerVM.bottomBarHidden = true
        } else if itemPagerVM.bottomBarHidden {
            self.itemPagerVM.bottomBarHidden = false
        }
    }
    private func calcContentSize() {
        self.itemPagerVM.contentSize.width = max(frameSize.width, getRect().width)
        self.itemPagerVM.contentSize.height = max(frameSize.height, getRect().height)
    }
    private func getContentSize() -> CGSize {
        return itemPagerVM.contentSize == .zero ? frameSize : itemPagerVM.contentSize
    }
    private func dismissPager() {
        withAnimation(.easeInOut) {
            onDismissTap()
        }
    }
    private func onDragCancelled() {
        withAnimation(.spring()) {
            if self.itemPagerVM.bgOpacity != 1 {
                self.itemPagerVM.bgOpacity = 1
            }
            if self.itemPagerVM.offsetY != CGFloat.zero {
                self.itemPagerVM.offsetY = CGFloat.zero
            }
        }
    }
    private struct TopBar: View {
        @Binding
        var currentIndex: Int
        let length: Int
        @Binding
        var minimized: Bool
        let dismissPager: () -> Void
        var body: some View {
            if !minimized {
                Text(length > 1 ? "number \((currentIndex + 1)) of \(length) total" : "")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(
                        BackButtonView(accentColor: .white, onCloseTap: dismissPager)
                            .padding(.leading, 8)
                     , alignment: .bottomLeading)
                    .padding(.top, max((safeEdges?.top ?? 0), 10))
                    .padding(.horizontal, (safeEdges?.left ?? 0))
                    .padding(.bottom, 10)
                    .background(Color.black.opacity(0.7))//.ignoresSafeArea()
                    .transition(.move(edge: .top))
            }
        }
    }
    private struct BottomBar: View {
        @Binding
        var currentImageItem: ImageItem?
        @Binding
        var minimized: Bool
        @State
        private var horizontalSpacing: CGFloat = 8
        @Environment(\.isHorizontal)
        private var isHorizontal
        var body: some View {
            if let _ = self.currentImageItem, !minimized {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let caption = getImageCaption() {
                            Text(caption)
                                .font(.caption)
                        }
                        if let author = currentImageItem?.author {
                            Text(author)
                                .font(.caption2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    imageShareButton
                }
                .foregroundColor(.white)
                .padding(.top, 8)
                .padding(.bottom, max((safeEdges?.bottom ?? 0), 10))
                // Weirdly sageEdges?.left did not work when rotating to landscape
                .padding(.horizontal, horizontalSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.7))
                .transition(.move(edge: .bottom))
                .onChange(of: isHorizontal) { _ in
                    self.horizontalSpacing = max((safeEdges?.left ?? 0), 8)
                }
            }
        }
        var imageShareButton: some View {
            Button(action: onImageShareAction, label: {
                Image("share")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding(.horizontal, 8)
            })
        }
        private func getImageCaption() -> String? {
            return currentImageItem?.title
        }
        private func onImageShareAction() {
            if let sensitiveURL = currentImageItem?.sensitive {
                sensitiveURL.shareSheet()
            } else if let imageRemotePath = currentImageItem?.getHd() {
                imageRemotePath.shareSheet()
            }
        }
    }
}
struct PagerContent: View {
    @Binding
    var selectedItemId: String
    let item: TextItem
    let frameSize: CGSize
    @Binding
    var translationY: CGFloat
    @Binding
    var gesturesDisabled: Bool
    @Binding
    var currentIndex: Int
    @Binding
    var barMinimized: Bool
    @Binding
    var bottomBarHidden: Bool
    
    let parentItemId: String
    let presentNewsItem: (NewsItem) -> Void
    let presentDetailMedia: (DetailMedia) -> Void
    
    @State
    private var contentWidth: CGFloat = .zero
    @State
    private var contentHeight: CGFloat = .zero
    
    @State
    private var contentScale: CGFloat = 1
    @State
    private var lastContentScale: CGFloat = 1
    @State
    private var seeSensitiveContent = false
    private var itemMagnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                adjustScale(value)
            }
            .onEnded { value in
                withAnimation(.interactiveSpring()) {
                    validateScaleLimits()
                }
                self.lastContentScale = 1
            }
    }
    @Environment(\.isHorizontal)
    private var isHorizontal
    var body: some View {
        ZStack(alignment: .leading) {
            ScrollView([.vertical, .horizontal], showsIndicators: false) {
                ItemContent(item: item, frameSize: frameSize, translationY: $translationY, canDisplaySensitive: $seeSensitiveContent, parentItemId: parentItemId, presentNewsItem: presentNewsItem, presentDetailMedia: presentDetailMedia, onDisplayed: {})
                    .frame(width: (contentWidth == .zero ? frameSize.width : contentWidth) * contentScale, height: (contentHeight == .zero ? frameSize.height : contentHeight) * contentScale)
                    // MARK: This hack to hide blured area getting out of bounds
                    .overlay(item.isSensitive() && !seeSensitiveContent ?
                             Rectangle().fill(Color.black)
                                .frame(width: CarouselConfig.padding)
                                .padding(.vertical, -10)
                                .offset(x: CarouselConfig.padding)
                             : nil, alignment: .trailing)
            }
        }
        .overlay(item.isSensitive() && !seeSensitiveContent ?
                 SensitiveWarningView(seeContent: $seeSensitiveContent, contentType: getSensitiveType(itemType: item.type, sourceType: item.embed?.source), shortVersion: false)
                    .frame(width: frameSize.width) : nil)
        .onAppear(perform: onPagerItemAppear)
        .onChange(of: seeSensitiveContent) { see in
            if see {
                self.bottomBarHidden = false
                self.gesturesDisabled = false
            }
        }
        .onChange(of: selectedItemId) { newSelectedId in
            if newSelectedId == item.id {
                if item.isSensitive() && seeSensitiveContent {
                    self.bottomBarHidden = false
                    self.gesturesDisabled = false
                }
            }
        }
        .gesture( !gesturesDisabled ?
            TapGesture(count: 2).onEnded {
                withAnimation {
                    contentScale = contentScale > 1 ? 1 : 4
                }
            }.exclusively(before: TapGesture(count: 1).onEnded {
                withAnimation(.easeInOut) {
                    self.barMinimized.toggle()
                }
            })
                .simultaneously(with: itemMagnification) : nil
        )
    }
    private func onPagerItemAppear() {
        calcItemSize(isHorizontal)
    }
    private func calcItemSize(_ isHor: Bool) {
        
    }
    private func adjustScale(_ value: MagnificationGesture.Value) {
        let newScale = contentScale * (value / lastContentScale) // Delta
        if newScale < AppConfig.GestureValues.MAX_SCALE_NUM && newScale > AppConfig.GestureValues.MIN_TMP_SCALE_NUM {
            self.contentScale = newScale
            self.lastContentScale = value
        }
    }
    private func validateScaleLimits() {
        if contentScale > AppConfig.GestureValues.MAX_SCALE_NUM {
            contentScale = AppConfig.GestureValues.MAX_SCALE_NUM
        } else if contentScale < 1 {
            contentScale = 1
        }
    }
    
    func getSensitiveType(itemType: TextItemType, sourceType: Embed.SourceType?) -> SensitiveType {
        if itemType == .image {
            return .photo
        } else if itemType == .embed {
            if sourceType == .bulbul || sourceType == .youtube {
                return .video
            }
        }
        return .other
    }
    
    struct ItemContent: View {
        let item: TextItem
        let frameSize: CGSize
        @Binding
        var translationY: CGFloat
        @Binding
        var canDisplaySensitive: Bool
        
        let parentItemId: String
        let presentNewsItem: (NewsItem) -> Void
        let presentDetailMedia: (DetailMedia) -> Void
        
        let onDisplayed: () -> ()
        @State
        private var displayed = false
        var body: some View {
            Group {
                if let imageItem = item.image, item.type == .image {
                    getImageItem(itemId: imageItem.id, imageItem)
                } else {
                    NewsTextObjectContent(textItem: item, parentItemId: parentItemId, contentSize: frameSize, presentNewsItem: presentNewsItem, presentDetailMedia: presentDetailMedia, placeholderMode: .thumb)
                        .padding(.top, max((safeEdges?.top ?? 0), 10))
                        .padding(.horizontal, (safeEdges?.left ?? 0))
                        .padding(.top, DefaultAppConfig.appNavBarHeight)
                }
            }
            .overlay(item.isSensitive() && !canDisplaySensitive ?
                     SensitiveCoverView(sensitiveItem: item, frameSize: frameSize)
                     : nil)
        }
        @ViewBuilder
        func getImageItem(itemId: String, _ imageItem: ImageItem) -> some View {
            AsyncImage(
                url: getRealImagePath(imageItem) ?? imageItem.thumb,
                placeholder: {
                    AsyncImage(
                        url: imageItem.sd ?? imageItem.thumb,
                        onlyCached: true,
                        placeholder: {
                            Color("GreyBg")
                                .aspectRatio(DefaultAppConfig.projectAspectRatio, contentMode: .fit)
                        }, failure: { Spacer() }
                    )
                }, failure: { Spacer() }
                , completion: { (state, _) in
                    if state == .displayed {
                        onDisplayed()
                        displayed = true
                    }
                }
            )
            .aspectRatio(contentMode: .fit)
            .offset(y: translationY)
        }
        private func getRealImagePath(_ image: ImageItem) -> URL? {
            return image.getHd(showSensitive: true)
        }
    }
}

struct ItemPager_Previews: PreviewProvider {
    static var previews: some View {
        ItemPager(items: [TextItem(image: ImageItem(id: "0", title: nil, author: nil, name: nil, thumb: URL(string: "https://st-0.newsapp.media/st_reporter/5/195551.700.jpg")!, sd: nil, hd: nil, sensitive: nil, width: nil, height: nil)), TextItem(id: "1_1", type: .image, tag: .img, content: nil, items: nil, link: nil, image: ImageItem(id: "1", title: nil, author: nil, name: nil, thumb: URL.init(string: "https://st-0.newsapp.media/img/other/warning-sensitive-content.jpg")!, sd: URL(string: "https://st-0.newsapp.media/img/other/warning-sensitive-content.jpg"), hd: URL(string: "https://st-0.newsapp.media/img/other/warning-sensitive-content.jpg"), sensitive: URL(string: "https://st-0.newsapp.media/st_gallery/93/1206593.2889ad5120e8703b667320747984bd85.jpg"), width: nil, height: nil), newsItem: nil, embed: nil, style: nil)], selectedItemId: .constant(""), parentItemId: "", frameSize: CGSize(width: 393, height: 852), presentNewsItem: { _ in }, presentDetailMedia: { _ in }, onDismissTap: {})
    }
}
