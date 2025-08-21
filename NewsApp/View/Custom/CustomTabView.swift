//
//  CustomTabView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CustomTabView: View {
    @StateObject
    var tabVM = TabsViewModel()
    @StateObject
    var stateVM = StateViewModel()
    @GestureState
    private var detailDragActive = false
    @State
    private var initLandscapeChecked = false
    @EnvironmentObject
    var appDelegate: AppDelegate
    var body: some View {
        GeometryReader { geo in
            ZStack {
                //NavigationView {
                //Tab pages
                VStack(spacing: .zero) {
                    TabView(selection: $tabVM.selectedTab) {
                        ForEach(tabVM.tabs) { tabItem in
                            //NavigationView {
                            if tabVM.selectedTab == tabItem.id {
                                if tabItem.id == "menu" {
                                    MenuView(onLoginPresent: presentLoginView)
                                        .analyticsScreen(name: tabItem.name, class: String(describing: MenuView.self))
                                        //, class: String(describing: MenuView.self)
                                        /*.onAppear {
                                            self.tabVM.scrollTarget.activeTabTargetPos = ""
                                        }*/
                                        /*.onAppear {
                                            self.sendTabItemScreenView(tabItem, className: String(describing: MenuView.self))
                                        }*/
                                        .tag(tabItem.id)
                                } else {
                                    FeedView(tabItem: tabItem, selectedTab: $tabVM.selectedTab, scrollTarget: $tabVM.scrollTarget, searchModeExpanded: $tabVM.searchModeExpanded, updatedItem: $tabVM.updatedFeedItem/*, topAdItem: $tabVM.topAdItem*/) { (feedItem, position) in
                                        //Task { @MainActor in
                                        self.presentDetailView(with: feedItem, at: position, on: FromPage(pageKey: tabItem.id, backText: tabItem.name), from: max(geo.size.width, getRect().width), and: max(geo.size.height, getRect().height))
                                        //}
                                    }
                                    .analyticsScreen(name: tabItem.name, class: String(describing: FeedView.self), extraParameters: self.tabVM.getAnalyticsExtraParams(for: tabItem))
                                    //class: String(describing: FeedView.self),
                                    /*.onAppear {
                                        self.sendTabItemScreenView(tabItem, className: String(describing: FeedView.self))
                                    }*/
                                    .tag(tabItem.id)
                                }
                            } else {
                                Color.clear
                                    .tag(tabItem.id)
                            }
                            //}
                        }
                    }
                    // Tab buttons
                    TabBarView(tabVM: tabVM)
                }
                .offset(x: tabVM.feedOffsetX)
                .animation(tabVM.feedOffsetX == .zero ? nil : .easeOut, value: tabVM.feedOffsetX)
                .zIndex(1)
                // Search Page
                if tabVM.searchModeExpanded {
                    SearchView(isPresented: $tabVM.searchModeExpanded) { feedItem in
                        self.presentDetailView(with: feedItem, at: .zero, on: FromPage(pageKey: "search", backText: "search"), from: max(geo.size.width, getRect().width), and: max(geo.size.height, getRect().height))
                    }
                        .zIndex(2)
                }
                // Splash screen
                if tabVM.tabs.count == 0 {
                    VStack(spacing: 0) {
                        TopBarView(leadingBtn: {}, logo: true, trailingBtn: {})
                        Spacer()
                        TabBarView(tabVM: tabVM)
                    }
                    .frame(maxHeight: .infinity)
                    .zIndex(2)
                    .background(Color("AccentLightColor").ignoresSafeArea())
                }
                // Can implement Any Detail
                if let detailedFeedItem = tabVM.detailedFeedItem {
                    DetailView(detailVM: DetailViewModel(feedItem: detailedFeedItem.item, presentLoginView: presentLoginView), feedItemDetail: $tabVM.detailedFeedItem, backText: tabVM.fromPageItem?.backText, fromPageKey: tabVM.fromPageItem?.pageKey ?? "unk", pushBackDisabled: $tabVM.pushBackDisabled, pushBackOffset: $tabVM.detailOffset/*, topAdItem: tabVM.topAdItem*/, onCloseTap: {
                        dismissDetail(fromBottom: detailedFeedItem.item.redirectable(), trailingPoint: max(geo.size.width, getRect().width), y: max(geo.size.height, getRect().height), .zero)
                    })
                    .offset(x: tabVM.detailOffset.x, y: tabVM.detailOffset.y)
                    .simultaneousGesture(!tabVM.pushBackDisabled ?
                        DragGesture(minimumDistance: 40)
                            .updating($detailDragActive) { _, out, _ in
                                out = true
                            }.onChanged { value in
                                let dragOffsetX = value.translation.width
                                if dragOffsetX > 0 {
                                    self.calcLayerOffset(dragOffsetX: dragOffsetX, contentWidth: geo.size.width)
                                }
                            }.onEnded { value in
                                let endOffsetX = value.translation.width
                                if endOffsetX >= abs(AppConfig.GestureValues.BACK_VIEW_OFFSET_X) {
                                    self.dismissDetail(fromBottom: false, trailingPoint: max(geo.size.width, getRect().width), y: .zero, value.predictedEndTranslation.width)//velocity: value.predictedEndLocation.x - value.location.x,
                                } else {
                                    self.presentDetailOffset()
                                }
                            } : nil)
                    .zIndex(3)
                }
                // Login View
                if let _ = tabVM.loginViewItem {
                    LoginView(loginItem: $tabVM.loginViewItem)
                        .zIndex(4)
                        .transition(.move(edge: .bottom))
                }
            }
            .onRotate { newOrientation in
                withAnimation(.easeInOut) {
                    tabVM.setIsHorizontal(newOrientation == .landscapeLeft || newOrientation == .landscapeRight || (!initLandscapeChecked && getRect().width > getRect().height))
                    if initLandscapeChecked == false {
                        initLandscapeChecked = true
                    }
                }
            }
            .onReceive(appDelegate.$pushNotItem) { pushItem in
                if let newsItem = pushItem?.newsItem {
                    self.presentDetailView(with: FeedItem(newsItem: newsItem), at: -1, on: FromPage(pageKey: "push", backText: nil), from: getRect().width, and: .zero)
                    self.appDelegate.pushNotItem = nil
                } else if let linkItem = pushItem?.linkItem {
                    Task { @MainActor in
                        if let url = linkItem.link {
                            self.stateVM.webViewItem = WebViewItem(url: url, dismissCallback: { _ in false })
                        }
                        self.appDelegate.pushNotItem = nil
                    }
                }
            }
            .isHorizontal(tabVM.isHorizontal)
            .onAppear(perform: onTabViewAppear)
            .overlay(stateVM.alertPresented()
                     ? CustomAlert(content: stateVM.alertContent)
                        .preferredColorScheme(stateVM.alertColorScheme())
                     : nil)
            .overlay(stateVM.imagePickerSheet != nil ? ImagePickerSheetView() : nil)
            .overlay(stateVM.sheetPresented() ? CustomActionSheet(content: stateVM.sheetContent) : nil)
            .fullScreenCover(item: $stateVM.webViewItem, content: { item2Load in
                WebView(urlItem: item2Load, onDismiss: { self.stateVM.webViewItem = nil })
            })
            .environmentObject(stateVM)
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            if tabVM.sendDeviceState == .inited {
                tabVM.sendDeviceInfo()
            }
        }
    }
    private func onTabViewAppear() {
        if UIDevice.current.orientation.isLandscape {
            tabVM.setIsHorizontal(true)
        }
        FCMService.shared.subscribeToTopicIfEnabled(DefaultAppConfig.MAIN_PUSH_NOT_TOPIC, pref: .mainNotification)
    }
    private func presentDetailView(with item: FeedItem, at pos: Int, on page: FromPage?, from trailingPosX: CGFloat, and y: CGFloat) {
        Task { @MainActor in
            var feedOffsetX = CGFloat.zero
            if item.redirectable() {
                tabVM.detailOffset.x = .zero
                tabVM.detailOffset.y = y
            } else {
                tabVM.detailOffset.x = trailingPosX
                tabVM.detailOffset.y = .zero
                feedOffsetX = AppConfig.GestureValues.BACK_VIEW_OFFSET_X
            }
            tabVM.fromPageItem = page
            tabVM.detailedFeedItem = FeedItemDetail(item: item, position: pos)
            withAnimation(.interactiveSpring()) {
                tabVM.detailOffset = .zero
                tabVM.feedOffsetX = feedOffsetX
            }
        }
    }
    private func dismissDetail(fromBottom: Bool, trailingPoint x: CGFloat, y: CGFloat, _ predictedEndWidth: CGFloat) {//velocity: CGFloat,
        Task { @MainActor in
            self.tabVM.detailDismissActive = true
            if fromBottom {
                self.tabVM.feedOffsetX = .zero
            }
            if predictedEndWidth >= x {
                self.dismissDetailOffset(fromBottom, x, y)
            } else {
                withAnimation(.linear(duration: fromBottom ? 0.2 : 0.3)) {
                    self.dismissDetailOffset(fromBottom, x, y)
                }
            }
            withAnimation(.default.delay(0.4)) {
                self.tabVM.resetDetailItem()
            }
        }
    }
    private func dismissDetailOffset(_ fromBottom: Bool, _ x: CGFloat, _ y: CGFloat) {
        if fromBottom {
            tabVM.detailOffset.y = y
        } else {
            tabVM.feedOffsetX = .zero
            tabVM.detailOffset.x = x
        }
        if let detailedFeedItem = self.tabVM.detailedFeedItem {
            self.tabVM.updatedFeedItem = detailedFeedItem
        }
    }
    private func presentDetailOffset(_ delay: Double = 0.3) {
        // MARK: Animate using animation(:value:)
        withAnimation(.easeInOut.delay(delay)) {
            tabVM.detailOffset.x = .zero
            tabVM.feedOffsetX = AppConfig.GestureValues.BACK_VIEW_OFFSET_X
        }
    }
    private func presentLoginView(loginItem: LoginViewItem) {
        withAnimation {
            tabVM.loginViewItem = loginItem
        }
    }
    private func calcLayerOffset(dragOffsetX: CGFloat, contentWidth: CGFloat) {
        Task { @MainActor in
            var backOffset: CGFloat = AppConfig.GestureValues.BACK_VIEW_OFFSET_X -  ((((dragOffsetX/contentWidth)*100)/100) * AppConfig.GestureValues.BACK_VIEW_OFFSET_X)
            if backOffset > 0 {
                backOffset = 0
            } else if backOffset < AppConfig.GestureValues.BACK_VIEW_OFFSET_X {
                backOffset = AppConfig.GestureValues.BACK_VIEW_OFFSET_X
            }
            if !detailDragActive && !tabVM.detailDismissActive {
                self.presentDetailOffset(0.1)
            } else {
                withAnimation(.easeOut) {
                    self.tabVM.detailOffset.x = dragOffsetX
                    self.tabVM.feedOffsetX = backOffset
                }
            }
        }
    }
}
private struct TabBarView: View {
    @StateObject
    var tabVM: TabsViewModel
    var body: some View {
        VStack(spacing: .zero) {
            Divider()
                .background(Color("GreyTint"))
            HStack(alignment: .top, spacing: .zero) {
                Spacer(minLength: .zero)
                if tabVM.tabs.count == .zero {
                    TabButton(tabItem: nil, selectedTabId: $tabVM.selectedTab, isHorizontal: $tabVM.isHorizontal, scrollTopAction: scrollTopOnTabReselect)
                } else {
                    ForEach(tabVM.tabs) { tab in
                        TabButton(tabItem: tab, selectedTabId: $tabVM.selectedTab, isHorizontal: $tabVM.isHorizontal, scrollTopAction: scrollTopOnTabReselect)
                        Spacer(minLength: .zero)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, tabVM.isHorizontal ? 4 : 8)
            .padding(.bottom, safeEdges?.bottom == .zero ? 8 : safeEdges?.bottom)
        }
        .background(Color("WhiteDarker").ignoresSafeArea(.all, edges: .bottom))
    }
    private func scrollTopOnTabReselect() {
        withAnimation(.easeOut) {
            tabVM.onTabReselect(direction: .top)
        }
    }
}

struct TabButton: View {
    var tabItem: TabItem?
    @Binding
    var selectedTabId: String
    @Binding
    var isHorizontal: Bool
    let scrollTopAction: () -> Void
    private var isSelectedTab: Bool {
        selectedTabId == tabItem?.id
    }
    private var iconSize: CGSize {
        CGSize(width: isHorizontal ? 18 : 24, height: isHorizontal ? 18 : 24)
    }
    var body: some View {
        if let tabItem = tabItem {
            Button(action: {
                if tabItem.key != selectedTabId {
                    self.selectedTabId = tabItem.key
                } else {
                    self.scrollTopAction()
                }
            }) {
                tabButtonContent()
            }
        } else {
            tabButtonContent()
        }
    }
    @ViewBuilder
    private func tabButtonContent() -> some View {
        VStack(spacing: 4) {
            iconView()
                .foregroundColor(isSelectedTab
                                    ? Color("PrimaryColor")
                                    : Color("GreyDark"))
                .padding(.all, 1)
                .frame(width: iconSize.width, height: iconSize.height)
            Text(tabItem?.name ?? "")
                .font(.system(size: 12, weight: .light, design: .default))
                .foregroundColor(isSelectedTab
                                    ? Color("PrimaryColor")
                                    : Color("GreyDark"))
        }
        .padding(.leading, tabItem?.id == "menu" ? 4 : 0)
        .padding(.trailing, tabItem?.id == "menu" ? 2 : 0)
    }
    @ViewBuilder
    private func iconView() -> some View {
        if let iconAsset = tabItem?.icon {
            Image(isSelectedTab ? (iconAsset.filled ?? iconAsset.name) : iconAsset.name)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if let systemIc = tabItem?.sysIcName {
            Image(systemName: isSelectedTab ? (systemIc.filled ?? systemIc.name) : systemIc.name)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Rectangle()
                .fill(Color.clear)
                .frame(width: iconSize.width, height: iconSize.height)
        }
    }
}

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabView()
    }
}
