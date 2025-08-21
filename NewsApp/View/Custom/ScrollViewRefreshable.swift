//
//  ScrollViewRefreshable.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 12/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct ScrollViewRefreshable<Content: View, Header: View, Footer: View>: View {
    @Binding
    var scrollTarget: MoveDirection?
    //var scrollTarget: String?
    /*@Binding
    var disableRefresh: Bool*/
    
    let rowBg: Color
    let wrapVStack: Bool
    
    let header: () -> Header
    let content: () -> Content
    let footer: () -> Footer
    
    let onFooterReach: () -> Void
    
    let onRefreshAsync: OnRefreshAsync
    let onRefreshClosure: OnRefresh
    
    //let onRefresh: () -> Void = {}
    init(scrollTarget: Binding<MoveDirection?>, rowBg: Color = Color("AccentLightColor"), wrapVStack: Bool = false, @ViewBuilder header: @escaping () -> Header, @ViewBuilder content: @escaping () -> Content, @ViewBuilder footer: @escaping () -> Footer, onFooterReach: @escaping () -> Void, onRefreshAsync: @escaping OnRefreshAsync, onRefreshClosure: @escaping OnRefresh) {//, disableRefresh: Binding<Bool>
        self._scrollTarget = scrollTarget
        //self._disableRefresh = disableRefresh
        self.rowBg = rowBg
        self.wrapVStack = wrapVStack
        
        self.header = header
        self.content = content
        self.footer = footer
        
        self.onFooterReach = onFooterReach
        
        self.onRefreshAsync = onRefreshAsync
        self.onRefreshClosure = onRefreshClosure
    }
    var body: some View {
        //RefreshableScrollViewPre15(scrollTarget: $scrollTarget, disableRefresh: $disableRefresh, content: content, onRefresh: onRefresh)
        if #available(iOS 15, *) {
            RefreshableListView(scrollTarget: $scrollTarget, rowBg: rowBg, wrapVStack: wrapVStack, header: header, content: content, footer: footer, onRefresh: onRefreshAsync)
        } else {
            RefreshableViewPre15(content: {
                LazyVStack(alignment: .leading, spacing: .zero) {
                    header()
                    content()
                    footer()
                }
            }, onRefresh: onRefreshClosure, onFooterReach: onFooterReach)
        }
    }
}
@available(iOS 15.0, *)
struct RefreshableListView<Content: View, Header: View, Footer: View>: View {
    @Binding
    var scrollTarget: MoveDirection?
    let rowBg: Color
    let wrapVStack: Bool
    
    let header: () -> Header
    let content: () -> Content
    let footer: () -> Footer
    let onRefresh: () async -> Void
    
    init(scrollTarget: Binding<MoveDirection?>,
         rowBg: Color,
         wrapVStack: Bool,
         @ViewBuilder header: @escaping () -> Header,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder footer: @escaping () -> Footer,
         onRefresh: @escaping () async -> Void) {//, disableRefresh: Binding<Bool>
        self._scrollTarget = scrollTarget
        //self._disableRefresh = disableRefresh
        self.rowBg = rowBg
        self.wrapVStack = wrapVStack
        
        self.header = header
        self.content = content
        self.footer = footer
        
        self.onRefresh = onRefresh
    }
    var body: some View {
        ScrollViewReader { proxy in
            if wrapVStack {
                VStack {
                    ListContent
                        .onChange(of: scrollTarget) { onScrollTargetChange($0, proxy) }
                }
            } else {
                ListContent
                    .onChange(of: scrollTarget) { onScrollTargetChange($0, proxy) }
            }
        }
    }
    private var ListContent: some View {
        List {
            header()
                .listRowInsets(EdgeInsets(.zero))
                .listRowSeparator(.hidden)
                .listRowSeparatorTint(.clear)
                .listRowBackground(rowBg)
            content()
                .listRowInsets(EdgeInsets(.zero))
                .listRowSeparator(.hidden)
                .listRowSeparatorTint(.clear)
                .listRowBackground(rowBg)
            footer()
                .listRowInsets(EdgeInsets(.zero))
                .listRowSeparator(.hidden)
                .listRowSeparatorTint(.clear)
                .listRowBackground(rowBg)
        }
        .environment(\.defaultMinListRowHeight, 1)
        .listStyle(.plain)
        .refreshable {
            await onRefresh()
        }
    }
    private func onScrollTargetChange(_ target: MoveDirection?, _ proxy: ScrollViewProxy) {
        if target == .top {
            self.scrollTarget = nil
            //withAnimation {
            proxy.scrollTo(DefaultAppTabConfig.TOP_ITEM_ID_FOR_SCROLL, anchor: .top)
            //}
        }
    }
}

typealias OnRefreshAsync = () async -> Void
typealias RefreshComplete = () -> Void
typealias OnRefresh = (@escaping RefreshComplete) -> Void


struct RefreshableViewPre15<Content: View>: View {
    @ViewBuilder
    let content: () -> Content
    let onRefresh: OnRefresh
    
    let onFooterReach: () -> Void

    init(@ViewBuilder content: @escaping () -> Content, onRefresh: @escaping OnRefresh, onFooterReach: @escaping () -> Void) {
        self.content = content
        self.onRefresh = onRefresh
        self.onFooterReach = onFooterReach
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollViewControllerRepresentable(content: {
                content()
                    .frame(width: proxy.size.width)
                    .ignoresSafeArea()
            }, onRefresh: onRefresh, onFooterReach: onFooterReach)
        }
    }
}

struct ScrollViewControllerRepresentable<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder
    let content: () -> Content
    let onRefresh: OnRefresh
    
    let onFooterReach: () -> Void
    
    //@Environment(\.refresh) private var action
    @State
    var isRefreshing: Bool = false
    private let refreshControl = UIRefreshControl()

    init(@ViewBuilder content: @escaping () -> Content, onRefresh: @escaping OnRefresh, onFooterReach: @escaping () -> Void) {
        self.content = content
        self.onRefresh = onRefresh
        self.onFooterReach = onFooterReach
    }

    func makeUIViewController(context: Context) -> UIScrollViewController<Content> {
        let viewController = UIScrollViewController(
            refreshControl: refreshControl,
            view: content(),
            onFooterReach: onFooterReach
        )
        viewController.onRefresh = {
            self.isRefreshing = true
            self.onRefresh({
                self.isRefreshing = false
            })
        }
        return viewController
    }

    func updateUIViewController(_ viewController: UIScrollViewController<Content>, context: Context) {
        viewController.hostingController.rootView = content()
        viewController.hostingController.view.setNeedsUpdateConstraints()

        if isRefreshing {
            viewController.refreshControl.beginRefreshing()
        } else {
            viewController.refreshControl.endRefreshing()
        }
    }
}

class UIScrollViewController<Content: View>: UIViewController, UIScrollViewDelegate {
    let scrollView = UIScrollView()
    let refreshControl: UIRefreshControl
    let hostingController: UIHostingController<Content>

    var onRefresh: (() -> Void)?
    
    let onFooterReach: () -> Void

    init(refreshControl: UIRefreshControl, view: Content, onFooterReach: @escaping () -> Void) {
        self.refreshControl = refreshControl
        self.hostingController = .init(rootView: view)
        self.onFooterReach = onFooterReach
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
        scrollView.refreshControl = refreshControl
        scrollView.delegate = self

        hostingController.willMove(toParent: self)

        scrollView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])

        // `addChild` must be called *after* the layout constraints have been set, or a layout bug will occur
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        hostingController.view.backgroundColor = .clear
    }

    @objc func didPullToRefresh(_ sender: UIRefreshControl) {
        self.onRefresh?()
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if bottomEdge >= scrollView.contentSize.height {
            self.onFooterReach()
        }
    }
}
