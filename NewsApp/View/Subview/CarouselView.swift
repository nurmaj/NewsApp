//
//  SnapCarousel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 13/8/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CarouselView: View {
    @StateObject
    var viewModel: CarouselViewModel
    @Binding
    var pushBackOffsetX: CGFloat
    let frameWidth: CGFloat
    let layoutType: Media.Layout?
    var spacing: CGFloat = CarouselConfig.spacing
    var visiblePartItemWidth: CGFloat = CarouselConfig.visiblePartItemWidth
    
    var topSeparator = false
    
    let presentNavItem: (NewsItem) -> Void
    let onCarouselPresent: ([TextItem], String) -> Void
    let presentDetailMedia: (DetailMedia) -> Void
    
    private var contentSize: CGSize {
        let width = min(frameWidth, min(getRect().width, getRect().height))
        var aspectRatio: CGFloat = 16 / 9
        if let layoutType = layoutType, layoutType != .landscape {
            if layoutType == .square {
                aspectRatio = 1
            } else if layoutType == .portrait {
                aspectRatio = 10 / 16
            }
        }
        if viewModel.items.count == 1 {
            return CGSize(width: width, height: width / aspectRatio)
        }
        return CGSize(width: width - (spacing * 2) - (visiblePartItemWidth * 2),
               height: (width - (spacing * 2) - (visiblePartItemWidth * 2)) / aspectRatio)
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            SnapCarousel(numberOfItems: CGFloat(viewModel.items.count), spacing: spacing, visiblePartItemWidth: visiblePartItemWidth, contentWidth: contentSize.width, pushBackOffsetX: $pushBackOffsetX, onCarouselTaped: onCarouselTaped) {
                ForEach(viewModel.items) { item in
                    CarouselItemView(item: item, itemIndex: viewModel.getItemIndex(item), contentSize: contentSize, presentNavItem: presentNavItem, presentDetailMedia: presentDetailMedia)
                }
            }
        }
        .frame(width: frameWidth, height: contentSize.height, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 10)
        .overlay(topSeparator ? CustomDivider() : nil, alignment: .topLeading)
        .contentShape(Rectangle())
        .environmentObject(viewModel)
    }
    private func onCarouselTaped() {
        withAnimation(.spring()) {
            self.onCarouselPresent(viewModel.items, viewModel.selectedItemId)
        }
    }
}

struct SnapCarousel<Items: View>: View {
    let items: Items
    let numberOfItems: CGFloat
    let spacing: CGFloat
    let visiblePartItemWidth: CGFloat
    let contentWidth: CGFloat
    @Binding
    var pushBackOffsetX: CGFloat
    let onCarouselTaped: () -> Void
    private let leadingPadding: CGFloat
    private let totalTransition: CGFloat
    
    @EnvironmentObject
    var viewModel: CarouselViewModel
    
    @GestureState
    private var isDragActive = false
    @State
    private var switchDisabled = false
    
    init(numberOfItems: CGFloat,
         spacing: CGFloat,
         visiblePartItemWidth: CGFloat,
         contentWidth: CGFloat,
         pushBackOffsetX: Binding<CGFloat>,
         onCarouselTaped: @escaping () -> Void,
         @ViewBuilder items: @escaping () -> Items) {
        self.numberOfItems = numberOfItems
        self.spacing = spacing
        self.visiblePartItemWidth = visiblePartItemWidth
        self.contentWidth = contentWidth
        self._pushBackOffsetX = pushBackOffsetX
        self.onCarouselTaped = onCarouselTaped
        self.leadingPadding = spacing + visiblePartItemWidth
        self.totalTransition = contentWidth + spacing
        
        self.items = items()
    }
    var body: some View {
        // MARK: HStack works unless LazyHStack
        HStack(alignment: .top, spacing: spacing) {
            items
        }
        .onAppear {
            self.viewModel.calcOffset = numberOfItems == 1 ? .zero : leadingPadding
            self.viewModel.dragGestureEnded = true
        }
        .offset(x: viewModel.calcOffset + viewModel.activeOffsetX)
        .modifier(AnimationFinished(of: viewModel.activeOffsetX, completion: {
            if !viewModel.dragGestureEnded {
                self.viewModel.dragGestureEnded = true
            }
        }))
        .animation(.spring(), value: viewModel.activeOffsetX)
        .simultaneousGesture( !switchDisabled ?
            DragGesture(minimumDistance: 10).updating($isDragActive) { (currentState, out, _) in
                out = true
            }.onChanged { value in
                self.viewModel.activeOffsetX = value.translation.width
                onDragOffsetChange(value.translation.width)
            }.onEnded { value in
                self.calcOffsetOnEnd(value.translation.width)
            }.exclusively(before: viewModel.canTapOnItem() ? TapGesture(count: 1).onEnded(self.onCarouselTaped) : nil)
                              : nil
        )
        .onChange(of: isDragActive) { active in
            if active {
                self.viewModel.dragGestureEnded = false
            }
            if !active && !switchDisabled && viewModel.activeOffsetX != .zero {
                self.viewModel.activeOffsetX = .zero
            } else if !active && pushBackOffsetX > 0 {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.pushBackOffsetX = .zero
                }
            }
        }
        .onChange(of: self.pushBackOffsetX) { newOffsetX in
            if newOffsetX == .zero {
                self.viewModel.activeOffsetX = .zero
                self.switchDisabled = false
            }
        }
    }
    private func onDragOffsetChange(_ newOffset: CGFloat) {
        // MARK: Enable push back on first element
        if viewModel.selectedIndex == 0 && newOffset >= AppConfig.GestureValues.BACK_PUSH_THRESHOLD {
            self.switchDisabled = true
            self.pushBackOffsetX = max(newOffset - AppConfig.GestureValues.BACK_PUSH_THRESHOLD, 0)
        }
    }
    private func calcOffsetOnEnd(_ endOffset: CGFloat) {
        let prevCalcOffset = viewModel.calcOffset
        self.viewModel.activeOffsetX = .zero
        if endOffset < -CarouselConfig.SWITCH_THRESHOLD {
            if CGFloat(self.viewModel.selectedIndex + 1) < numberOfItems {
                viewModel.setSelectedItem(at: viewModel.selectedIndex + 1)
                self.viewModel.calcOffset = prevCalcOffset - totalTransition
            }
        } else if endOffset > CarouselConfig.SWITCH_THRESHOLD {
            if self.viewModel.selectedIndex - 1 >= .zero {
                viewModel.setSelectedItem(at: viewModel.selectedIndex - 1)
                self.viewModel.calcOffset = viewModel.calcOffset + totalTransition
            }
        }
    }
}

struct CarouselItemView: View {
    @EnvironmentObject
    var viewModel: CarouselViewModel
    let item: TextItem
    let itemIndex: Int
    let contentSize: CGSize
    var nonActiveHeightDecrease: CGFloat = CarouselConfig.decreaseOfNonActive
    
    let presentNavItem: (NewsItem) -> Void
    let presentDetailMedia: (DetailMedia) -> ()
    
    private var itemHeight: CGFloat {
        contentSize.height - (itemIndex == viewModel.selectedIndex ? .zero : nonActiveHeightDecrease)
    }
    
    @State
    private var contentCanAppear = false
    @State
    private var itemInVisibleArea = false
    
    var body: some View {
        ZStack {
            BgShapeView(color: Color("GreyBg"))
            if itemInVisibleArea && contentCanAppear {
                NewsTextObjectContent(textItem: item, parentItemId: viewModel.parentItemId, contentSize: CGSize(width: contentSize.width, height: itemHeight), presentNewsItem: presentNavItem, presentDetailMedia: presentDetailMedia)
                    .blur(radius: item.isSensitive() && !viewModel.seeSensitiveContent ? 14 : 0, opaque: true)
                    .overlay(item.isSensitive() && !viewModel.seeSensitiveContent ? SensitiveWarningView(seeContent: $viewModel.seeSensitiveContent, contentType: .photo, shortVersion: true) : nil)
            }
        }
        .frame(width: contentSize.width, height: itemHeight)
        .overlay(
            // Indicators
            viewModel.items.count > 1 ?
                Text("\(itemIndex + 1)/\(viewModel.items.count)")
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .medium))
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.8))
                )
                .padding(.trailing, 8)
                .padding(.top, 8)
                .opacity(itemIndex == viewModel.selectedIndex ? 1 : .zero)
            : nil
            , alignment: .topTrailing
        )
        .onChange(of: viewModel.dragGestureEnded) { ended in
            if ended {
                if itemInVisibleArea {
                    self.contentCanAppear = true
                    self.viewModel.dragGestureEnded = false
                } else if contentCanAppear {
                    self.itemInVisibleArea = false
                    self.contentCanAppear = false
                }
            }
        }
        .onReceive(viewModel.$selectedIndex) { newIndex in
            if itemIndex == newIndex || itemIndex == newIndex - 1 || itemIndex == newIndex + 1 {
                if !itemInVisibleArea {
                    self.itemInVisibleArea = true
                }
            } else if itemInVisibleArea {
                
            }
        }
    }
}

struct Carousel {
    enum IndicatorType: String {
        case line, digit, preview
    }
}
struct CarouselIndicator: View {
    @Binding
    var currentIndex: Int
    var length: Int = 0
    var indicator: Carousel.IndicatorType
    var body: some View {
        if indicator == .digit {
            // MARK: Solution #2
            Text("\(currentIndex + 1)/\(length)")
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .light))
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.8))
            )
        } else if indicator == .preview {
            
        } else {
            EmptyView()
        }
    }
}
