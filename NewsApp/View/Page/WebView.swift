//
//  WebView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 8/6/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: View {
    @Environment(\.colorScheme) var colorScheme
    let urlItem: WebViewItem?
    let onDismiss: () -> Void
    @StateObject
    var webViewModel = WebViewModel()
    @State
    fileprivate var progressValue: Float = 0.0
    var body: some View {
        if let urlItem = urlItem {
            VStack(spacing: 0) {
                WebViewTopBar(viewModel: webViewModel, onDismiss: dismissWebView)
                WebKitWebView(viewModel: webViewModel, urlItem: urlItem)
                if !self.webViewModel.barsMinimized {
                    WebViewBottomBar(viewModel: webViewModel)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.5)))
                }
            }
            .accentColor(colorScheme == .dark ? .white : .blue)
            .ignoresSafeArea(.all, edges: .all)
        }
    }
    private func dismissWebView() {
        withAnimation {
            onDismiss()
        }
    }
    func updateProgressBar(when: Int = 500, percentStep: Float = 0.2, onFinish: @escaping ()->() = {}) {
        let dispatchAfter = DispatchTimeInterval.milliseconds(when)
        DispatchQueue.main.asyncAfter(deadline: .now() + dispatchAfter) {
            if progressValue < 1.0 {
                progressValue += percentStep
                onFinish()
            }
        }
    }
}
extension WebView {
    struct UrlItem: Identifiable {
        var url: URL
        let dismissCallback: (URL) -> Bool
        var id: String {
            url.absoluteString
        }
        var host: String {
            url.hostName ?? ""
        }
        var https: Bool {
            url.scheme == "https"
        }
    }
}
typealias WebViewItem = WebView.UrlItem

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebViewBottomBar(viewModel: WebViewModel())
    }
}

struct WebKitWebView: UIViewRepresentable {
    @StateObject
    var viewModel: WebViewModel
    var urlItem: WebViewItem
    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let webKitView = WKWebView(frame: .zero, configuration: config)
        webKitView.allowsLinkPreview = false
        webKitView.navigationDelegate = context.coordinator
        webKitView.uiDelegate = context.coordinator
        webKitView.scrollView.delegate = context.coordinator
        Task { @MainActor in
            self.viewModel.urlItem = urlItem
        }
        webKitView.load(URLRequest(url: urlItem.url))
        return webKitView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if self.viewModel.didFinishLoading && self.viewModel.actionType == .load {
            self.viewModel.didFinishLoading = false
            uiView.reload()
            self.viewModel.actionType = .noType
        }
        if !self.viewModel.didFinishLoading && self.viewModel.actionType == .cancel {
            uiView.stopLoading()
            self.viewModel.didFinishLoading = false
            self.viewModel.actionType = .noType
        }
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel)
    }
    final class Coordinator: NSObject {
        @ObservedObject
        var viewModel: WebViewModel
        init(_ viewModel: WebViewModel) {
            self.viewModel = viewModel
        }
    }
}
extension WebKitWebView.Coordinator: WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.viewModel.didFinishLoading = true
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.viewModel.didFinishLoading = false
        if let currentUrl = webView.url {
            self.viewModel.urlItem?.url = currentUrl
        }
    }
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let redirectUrl = webView.url {
            self.viewModel.urlItem?.url = redirectUrl
        }
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            UIApplication.shared.open(navigationAction.request.url!, options: [:])
        }
        return nil
    }
    /*
    Mandatory overides
    */
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let requestedUrl = navigationAction.request.url {
            let dismiss = viewModel.disableNavigation(for: requestedUrl)
            if(dismiss) {
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            let offsetY = scrollView.contentOffset.y
            if offsetY > self.viewModel.offsetY && offsetY - self.viewModel.startOffsetY >= 10 && !self.viewModel.barsMinimized {
                withAnimation {
                    self.viewModel.barsMinimized = true
                }
            } else if offsetY < self.viewModel.offsetY && self.viewModel.startOffsetY - offsetY >= 10 && self.viewModel.barsMinimized {
                withAnimation {
                    self.viewModel.barsMinimized = false
                }
            } else if offsetY < -40 && self.viewModel.barsMinimized {
                self.viewModel.barsMinimized = false
            }
            if self.scrollDirectionChanged(currentY: offsetY) {
                self.viewModel.startOffsetY = self.viewModel.offsetY
            }
            self.viewModel.offsetY = offsetY > 0 ? offsetY : 0
        }
    }
    private func scrollDirectionChanged(currentY: CGFloat) -> Bool {
        if currentY < self.viewModel.offsetY && self.viewModel.offsetY > self.viewModel.startOffsetY {
            // Bottom
            return true
        } else if currentY > self.viewModel.offsetY && self.viewModel.offsetY < self.viewModel.startOffsetY {
            // Up
            return true
        }
        return false
    }
}

struct HTMLDataWebView: UIViewRepresentable {
    @StateObject
    var viewModel: DataWebViewModel
    @Binding
    var dynamicHeight: CGFloat
    var width: CGFloat
    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
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
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
    }
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
            self.viewModel.onPageFinish()
            
            webView.evaluateJavaScript("document.documentElement.scrollHeight", completionHandler: { (height, error) in
                if height != nil {
                    let newHeight = CGFloat(height as? Double ?? .zero)
                    self.dynamicHeight = newHeight != .zero ? newHeight : webView.scrollView.contentSize.height
                }
              })
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse {
                if response.statusCode >= 400 {
                    viewModel.onPageFailed(response.statusCode)
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

class WebViewModel: ObservableObject {
    @Published
    var didFinishLoading: Bool = false
    @Published
    var urlItem: WebViewItem?
    @Published
    var offsetY: CGFloat = .zero
    @Published
    var startOffsetY: CGFloat = .zero
    @Published
    var barsMinimized: Bool = false
    @Published
    fileprivate var actionType: WebActionType = .noType
    func isSecure() -> Bool {
        return urlItem?.https ?? false
    }
    func hostName() -> String {
        return urlItem?.host ?? "about:blank"
    }
    func disableNavigation(for url: URL) -> Bool {
        return urlItem?.dismissCallback(url) ?? false
    }
}
class DataWebViewModel: ObservableObject {
    @Published
    var html: String?
    @Published
    var loadUrl: URL?
    @Published
    var dataMime: String?
    @Published
    var loadOnce: Bool = false
    @Published
    var onPageFinish: () -> Void = {}
    @Published
    var onPageFailed: (Int) -> Void = {_ in}
    @Published
    var onNavAction: (URL) -> Void = {_ in}
    init(with html: String?, or loadUrl: URL?, dataMime: String?, loadOnce: Bool, onPageFinish: @escaping ()->Void = {}, onPageFailed: @escaping (Int)->Void = { _ in }, onNavAction: @escaping (URL) -> Void = {_ in}) {
        self.html = html
        self.loadUrl = loadUrl
        self.dataMime = dataMime
        self.loadOnce = loadOnce
        self.onPageFinish = onPageFinish
        self.onPageFailed = onPageFailed
        self.onNavAction = onNavAction
    }
    init() {
        
    }
    func setupAllProperties(html: String?, loadUrl: URL?, dataMime: String?, loadOnce: Bool, onPageFinish: @escaping ()->Void, onPageFailed: @escaping (Int)->Void, onNavAction: @escaping (URL) -> Void) {
        self.html = html
        self.loadUrl = loadUrl
        self.dataMime = dataMime
        self.loadOnce = loadOnce
        self.onPageFinish = onPageFinish
        self.onPageFailed = onPageFailed
        self.onNavAction = onNavAction
    }
}
/* Helpers */
fileprivate enum WebActionType {
    case noType, load, cancel
}
fileprivate struct ProgressBar: View {
    @Binding
    var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .opacity(0.2)
                .foregroundColor(.black)
                .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width))
                .animation(.linear)
        }
    }
}

fileprivate struct WebViewTopBar: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isHorizontal) private var isHorizontal
    @StateObject
    var viewModel: WebViewModel
    let onDismiss: () -> Void
    private var bgColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    @State
    private var leadingBtnWidth = CGFloat.zero
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: {
                onDismiss()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("close")
                    .font(.system(size: 16))
                    .foregroundColor(Color.blue)
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            self.leadingBtnWidth = geo.size.width
                        }
                }
            )
            .overlay( viewModel.barsMinimized ?
                      bgColor
                        .contentShape(Rectangle())
                        .transition(.opacity) : nil
            )
            Spacer(minLength: .zero)
            HStack(alignment: .center, spacing: .zero) {
                Image(systemName: viewModel.isSecure() ? "lock.fill" : "lock.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12, alignment: .trailing)
                    .padding(.trailing, 4)
                Text(viewModel.hostName())
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .frame(alignment: .leading)
                    .padding(.trailing, 4)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .scaleEffect(viewModel.barsMinimized ? 0.8 : 1.0, anchor: .top)
            Spacer(minLength: .zero)
            ZStack(alignment: .trailing) {
                if viewModel.didFinishLoading {
                    Button(action: {
                        viewModel.actionType = .load
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .imageScale(.medium)
                    }
                } else {
                    Button(action: {
                        viewModel.actionType = .cancel
                    }) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                    }
                }
            }
            .foregroundColor(Color.blue)
            .padding(.trailing, 10)
            .frame(minWidth: leadingBtnWidth, alignment: .trailing)
            .overlay( viewModel.barsMinimized ?
                      bgColor
                        .contentShape(Rectangle())
                        .transition(.opacity): nil
            )
        }
        .onTapGesture {
            if viewModel.barsMinimized {
                viewModel.barsMinimized = false
            }
        }
        .padding(.top, safeEdges?.top ?? (viewModel.barsMinimized ? 0 : 18))
        .padding(.bottom, viewModel.barsMinimized ? 6 : (isHorizontal ? 8 : 18))
        .padding(.horizontal, isHorizontal ? 40 : 10)
        .background(bgColor)
        .overlay(
            CustomDivider()
            , alignment: .bottom
        )
    }
}
fileprivate struct WebViewBottomBar: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isHorizontal) private var isHorizontal
    @StateObject
    var viewModel: WebViewModel
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 2)
                .frame(maxHeight: 20)
                .foregroundColor(.clear)
            Rectangle()
                .frame(minWidth:0, maxWidth: .infinity, maxHeight: 20)
                .foregroundColor(.clear)
            Spacer(minLength: 2)
            Rectangle()
                .frame(minWidth:0, maxWidth: .infinity, maxHeight: 20)
                .foregroundColor(.clear)
            Spacer(minLength: 2)
            Button(action: {
                self.viewModel.urlItem?.url.shareSheet()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
                    .frame(minWidth:0, maxWidth: .infinity)
            }
            Spacer(minLength: 2)
            if let safariUrl = self.viewModel.urlItem?.url {
                Link(destination: safariUrl) {
                    Image(systemName: "safari")
                        .imageScale(.large)
                        .frame(minWidth:0, maxWidth: .infinity)
                }
                Rectangle()
                    .frame(width: 2)
                    .frame(maxHeight: 20)
                    .foregroundColor(.clear)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, isHorizontal ? 40 : 10)
        .padding(.top, isHorizontal ? 4 : 10)
        .padding(.bottom, (safeEdges?.bottom ?? 0) + (isHorizontal ? 0 : 10))
        .background((colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea(.all, edges: .bottom))
        .transition(.move(edge: .bottom))
        .overlay(
            CustomDivider()
            , alignment: .top
        )
    }
}
