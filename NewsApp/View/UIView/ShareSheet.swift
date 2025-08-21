//
//  ShareSheet.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 26/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let shareUrl: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let shareController = UIActivityViewController(activityItems: [shareUrl], applicationActivities: nil)
        return shareController
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}
