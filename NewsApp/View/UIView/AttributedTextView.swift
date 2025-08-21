//
//  AttributedTextView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 30/4/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
struct AttributedTextView: UIViewRepresentable {
    var text: String
    var textSize: CGFloat = 18
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: textSize)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.allowsEditingTextAttributes = false
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        textView.dataDetectorTypes = .all
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(Color("BlueLink"))
        ]
        textView.setAttributedText(fromHtml: text)
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            uiView.textColor = UIColor(Color("BlackTint"))
        }
    }
}
