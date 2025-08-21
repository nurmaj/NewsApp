//
//  ZoomableScrollView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/3/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let frameSize: CGSize
    @Binding
    var contentSize: CGSize
    @Binding
    var contentScale: CGFloat
    @Binding
    var dragTranslationY: CGFloat
    let dragChange: () -> Void
    let dragEnd: () -> Void
    private let content: Content

    init(frameSize: CGSize, contentSize: Binding<CGSize>, contentScale: Binding<CGFloat>, dragTranslationY: Binding<CGFloat>, dragChange: @escaping () -> Void, dragEnd: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.frameSize = frameSize
        self._contentSize = contentSize
        self._contentScale = contentScale
        self._dragTranslationY = dragTranslationY
        self.dragChange = dragChange
        self.dragEnd = dragEnd
        self.content = content()
    }
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = AppConfig.GestureValues.MAX_SCALE_NUM
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        
        // create a UIHostingController to hold our SwiftUI content
        if let hostedView = context.coordinator.hostingController.view {
            hostedView.translatesAutoresizingMaskIntoConstraints = true
            hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostedView.frame = scrollView.bounds
            hostedView.backgroundColor = UIColor.clear
            scrollView.addSubview(hostedView)
        }
        let panRecognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.onPan(_:)))
        panRecognizer.delegate = context.coordinator
        scrollView.addGestureRecognizer(panRecognizer)
        scrollView.isUserInteractionEnabled = true
        return scrollView
    }
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content), frameSize: frameSize, contentSize: $contentSize, contentScale: $contentScale, dragTranslationY: $dragTranslationY, dragChange: dragChange, dragEnd: dragEnd)
    }
    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        let hostingController: UIHostingController<Content>
        let frameSize: CGSize
        @Binding
        var contentSize: CGSize
        @Binding
        var contentScale: CGFloat
        @Binding
        var dragTranslationY: CGFloat
        let dragChange: () -> Void
        let dragEnd: () -> Void
        init(hostingController: UIHostingController<Content>, frameSize: CGSize, contentSize: Binding<CGSize>, contentScale: Binding<CGFloat>, dragTranslationY: Binding<CGFloat>, dragChange: @escaping () -> Void, dragEnd: @escaping () -> Void) {
            self.hostingController = hostingController
            self.frameSize = frameSize
            self._contentSize = contentSize
            self._contentScale = contentScale
            self._dragTranslationY = dragTranslationY
            self.dragChange = dragChange
            self.dragEnd = dragEnd
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            self.contentScale = scale
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        @objc func onPan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .changed {
                self.dragTranslationY = gesture.translation(in: gesture.view).y
                if self.contentScale == 1 {
                    self.dragChange()
                }
            } else if gesture.state == .ended {
                self.dragEnd()
                if self.contentScale == 1 {
                    return
                }
                if let pannedView = gesture.view, pannedView.isKind(of: UIScrollView.self) {
                    let scrollView = (pannedView as! UIScrollView)
                    var newContentOffset = scrollView.contentOffset
                    if (contentSize.width * contentScale) < frameSize.width {
                        newContentOffset.x = (scrollView.contentSize.width/2)/2
                    }
                    if (contentSize.height * contentScale) < frameSize.height {
                        newContentOffset.y = (scrollView.contentSize.height/2)/2
                    }
                    scrollView.isScrollEnabled = false
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                        scrollView.contentOffset = newContentOffset
                        scrollView.isScrollEnabled = true
                    }
                }
                if let pannedViewBounds = gesture.view?.bounds, (pannedViewBounds.origin.x != 0 || pannedViewBounds.origin.y != 0) {
                    
                }
            }
        }
    }
}
