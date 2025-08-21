//
//  AdView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 19/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import WebKit

struct AdView: View {
    @StateObject
    //@ObservedObject
    var viewModel: AdItemViewModel
    //@State
    private var isHorizontal: Bool {
        getRect().size.width > getRect().size.height
    }
    @StateObject
    var webViewModel = DataWebViewModel()
    let frameSize: CGSize
    private var bannerAlignment: Alignment {
        if viewModel.target == .topAllPage {
            return .top
        }
        return viewModel.target == .bottomFeed
            || viewModel.target == .bottomDetail ? .bottom : .center
    }
    private var screenSize: CGSize {
        getRect().size
    }
    private var bannerBgColor: Color {
        guard let bgColor = viewModel.adItem.bgColor else {
            return Color("GreyWhite")
        }
        return Color(hex: bgColor)
    }
    // MARK: For Checking of App Background and Foreground Mode
    @Environment(\.scenePhase) var scenePhase
    @State
    private var restartGif = true
    /*@State
    private var onGifAction: GIFClosure = { }*/
    var body: some View {
        //if let adItem = viewModel.adItem {
        GeometryReader { geo in
            if let bannerUrl = URL(string: viewModel.adItem.bannerPath) {
                ZStack(alignment: bannerAlignment) {
                    Button(action: onAdBannerClick) {
                        //Color.clear
                        if viewModel.adItem.type == .gif {
                            /*HTMLDataWebView(html: nil, loadUrl: bannerUrl, dataMime: "image/gif", dynamicHeight: $viewModel.bannerHeight, width: geo.size.width, onPageFinish: {viewModel.setAdShowed()}, onPageFailed: { _ in
                             self.viewModel.closeAdView(closingWhere: .loadFailed)
                             })*/
                            if let bannerData = viewModel.bannerData {
                                GIFImage(data: bannerData, restartGif: $restartGif)//, restartAnimation: $onGifAction
                                    .frame(width: viewModel.adFrameSize.width, height: viewModel.adFrameSize.height, alignment: .center)
                                    .overlay(viewModel.target == .fullscreenFeed || viewModel.target == .fullscreenDetail ? AdTimerView(viewModel: viewModel) : nil, alignment: .bottomTrailing)
                                    .overlay(AdCloseButton(viewModel: viewModel), alignment: .topTrailing)
                                    .onAppear(perform: onAdViewAppear)
                                    .onDisappear {
                                        self.restartGif = false
                                    }
                            }
                            if let _ = webViewModel.loadUrl {
                                
                            }
                        } else if viewModel.adItem.type == .jpeg || viewModel.adItem.type == .jpg || viewModel.adItem.type == .png {
                            AsyncImage(url: bannerUrl, placeholder: { Spacer() }, failure: { Spacer() }, completion: { (state,_) in
                                if state == .displayed {
                                    self.viewModel.setAdShowed()
                                } else if state == .failure {
                                    self.viewModel.closeAdView(closingWhere: .loadFailed)
                                }
                            })
                            .frame(maxWidth: viewModel.adFrameSize.width, maxHeight: viewModel.adFrameSize.height)
                            .overlay(viewModel.isFullscreenAd() ? AdTimerView(viewModel: viewModel) : nil, alignment: .bottomTrailing)
                            .overlay(AdCloseButton(viewModel: viewModel), alignment: .topTrailing)
                        } else {
                            EmptyView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // MARK: Download Banner GIF Data
                    if viewModel.adItem.type == .gif {
                        viewModel.getRemoteBannerData(remoteUrl: bannerUrl)
                    }
                    
                    // MARK: Re-init is heavy task so init only once
                    if webViewModel.loadUrl == nil {
                        webViewModel.setupAllProperties(html: nil, loadUrl: bannerUrl, dataMime: "image/gif", loadOnce: false, onPageFinish: viewModel.setAdShowed, onPageFailed: { _ in
                            self.viewModel.closeAdView(closingWhere: .loadFailed)
                        }, onNavAction: {_ in})
                    }
                    calcFrameSize()
                }
                .onChange(of: isHorizontal) { horizontal in
                    withAnimation(.easeInOut) {
                        calcFrameSize()
                    }
                }
            }
        }
        .frame(minHeight: viewModel.adItem.target == .topAllPage ? viewModel.adFrameSize.height : .zero, maxHeight: viewModel.isFullscreenAd() ? .infinity : viewModel.adFrameSize.height)
        //.frame(height: viewModel.isFullscreenAd() ? screenSize.height : viewModel.adFrameSize.height)
        .padding(.bottom, viewModel.target == .topAllPage ? 6 : .zero)
        .padding(.bottom, viewModel.target == .bottomDetail ? (safeEdges?.bottom ?? 10) : .zero)
        .background( (viewModel.target == .topAllPage || isHorizontal ? Color.clear : bannerBgColor).ignoresSafeArea() )
    }
    private func onAdViewAppear() {
        //self.onGifAction()
        self.restartGif = true
        viewModel.setAdShowed()
    }
    private func onAdBannerClick() {
        self.viewModel.closeAdView(closingWhere: .onBannerClick)
        if UIApplication.shared.canOpenURL(viewModel.adItem.url) {
            UIApplication.shared.open(viewModel.adItem.url)
        }
    }
    private func calcFrameSize() {
        var aspectRatio = CGFloat(viewModel.adItem.aspectRatio)
        if aspectRatio <= .zero && viewModel.adItem.width > .zero && viewModel.adItem.height > .zero {
            aspectRatio = (CGFloat(viewModel.adItem.width) / CGFloat(viewModel.adItem.height))
        }
        var adBannerWidth = isHorizontal ? min(screenSize.height, frameSize.height) : min(screenSize.width, frameSize.width)
        var adBannerHeight = adBannerWidth / aspectRatio
        if viewModel.isFullscreenAd() {
            if isHorizontal {
                adBannerHeight =  min(getRect().height, frameSize.height)
                adBannerWidth = aspectRatio < 1 ? adBannerHeight * aspectRatio : adBannerHeight / aspectRatio
            }
        } else if aspectRatio < 1 {
            adBannerHeight = adBannerHeight * aspectRatio
        }
        self.viewModel.adFrameSize.width = adBannerWidth
        self.viewModel.adFrameSize.height = adBannerHeight
    }
}
struct AdCloseButton: View {
    @StateObject
    var viewModel: AdItemViewModel
    private var topTrailingPadding: CGFloat {
        return viewModel.target == .bottomFeed
            || viewModel.target == .bottomDetail ? 0 : 4
    }
    var body: some View {
        if viewModel.target != .topAllPage {
            Button(action: {
                viewModel.closeAdView(closingWhere: .closeIcon)
            }) {
                Image(systemName: "xmark")
                    .font(viewModel.target == .bottomFeed
                            || viewModel.target == .bottomDetail ? .body : .title)
                    .padding(.all, 4)
                    //.frame(width: icWidth, height: icWidth)
                    .foregroundColor(.blue)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.9)))
            }
            .padding(.top, topTrailingPadding)
            .padding(.trailing, topTrailingPadding)
        } else {
            EmptyView()
        }
    }
}
struct AdTimerView: View {
    @StateObject
    var viewModel: AdItemViewModel
    var body: some View {
        Text("\((viewModel.adAutoCloseTime + 1))")
            .font(.body)
            .fontWeight(.medium)
            .lineLimit(1)
            .foregroundColor(.white)
            .frame(width: 20)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .padding(.trailing, 4)
            .padding(.bottom, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.8))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
            )
            .onReceive(viewModel.$adAutoCloseTime, perform: { tick in
                if tick >= (viewModel.adItem.skipTime ?? AdDefaults.DEFAULT_SKIP_TIMEOUT) {
                    viewModel.closeAdView(closingWhere: .timerEnd)
                }
            })
    }
}
struct AdWebView: UIViewRepresentable {
    @StateObject
    var viewModel: DataWebViewModel
    @Binding
    var dynamicHeight: CGFloat
    private static var webView: WKWebView?
    func makeUIView(context: Context) -> WKWebView {
        if let webView = Self.webView, webView.url == viewModel.loadUrl {
            return webView
        } else {
            let prefs = WKWebpagePreferences()
            prefs.allowsContentJavaScript = true
            
            let config = WKWebViewConfiguration()
            config.defaultWebpagePreferences = prefs
            let webView = WKWebView(frame: .zero, configuration: config)
            //let webView = WKWebView()
            webView.navigationDelegate = context.coordinator
            webView.scrollView.showsVerticalScrollIndicator = false
            webView.scrollView.showsHorizontalScrollIndicator = false
            webView.scrollView.bounces = false
            webView.scrollView.backgroundColor = .clear
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            webView.isOpaque = false
            webView.backgroundColor = .clear
            if let htmlStr = viewModel.html {
                webView.loadHTMLString(htmlStr, baseURL: nil)
            } else if let loadUrl = viewModel.loadUrl {
                if let dataMime = viewModel.dataMime {
                    let canLoadData = try? Data(contentsOf: loadUrl)
                    if let loadData = canLoadData {
                        webView.load(loadData, mimeType: dataMime, characterEncodingName: "UTF-8", baseURL: loadUrl)
                    }
                } else {
                    webView.load(URLRequest(url: loadUrl))
                }
            }
            Self.webView = webView
            return webView
        }
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel, _dynamicHeight)
    }
    final class Coordinator: NSObject, WKNavigationDelegate {
        @ObservedObject
        var viewModel: DataWebViewModel
        @Binding
        var dynamicHeight: CGFloat
        private var onlyOnceAllow: WKNavigationActionPolicy = .allow
        init(_ viewModel: DataWebViewModel, _ dynamicHeight: Binding<CGFloat>) {
            self.viewModel = viewModel
            self._dynamicHeight = dynamicHeight
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.frame.size.height = 1
            webView.frame.size = webView.scrollView.contentSize
            //DispatchQueue.main.async {
                self.viewModel.onPageFinish()
            //}
            webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
                if complete != nil {
                    self.dynamicHeight = webView.scrollView.contentSize.height
                }
              })
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse {
                if response.statusCode >= 400 {
                    //decisionHandler(.allow)
                    viewModel.onPageFailed(response.statusCode)
                    //return
                }
            }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let requestedUrl = navigationAction.request.url, viewModel.loadOnce, onlyOnceAllow == .cancel {
                if requestedUrl.scheme == "http" || requestedUrl.scheme == "https" {
                    // Open Fullscreen WebView
                    viewModel.onNavAction(requestedUrl)
                } else {
                    onlyOnceAllow = .allow
                }
            }
            decisionHandler(onlyOnceAllow)
            if viewModel.loadOnce && onlyOnceAllow == .allow {
                onlyOnceAllow = .cancel
            }
        }
    }
}
struct AdView_Previews: PreviewProvider {
    static var previews: some View {
        AdView(viewModel: AdItemViewModel(adItem: AdItem(id: "8", hashId: UUID().uuidString, target: .fullscreenFeed, url: URL(string: "#")!, bannerId: 17, bannerPath: "https://static.newsapp.media/st_reklama/8/8.468x120.jpg", bannerPathLandscape: nil, bgColor: nil, width: 468, height: 120, aspectRatio: 3.9, closeIcPath: "", showedTime: "", adIds: "", size: .SIZE_FEED, type: .gif, scaleMode: nil, linkType: .link, skipTime: nil, displayState: nil), /*state: .notReady, */target: .fullscreenFeed, from: "", closeAd: {}), frameSize: CGSize.zero)
    }
}
