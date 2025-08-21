//
//  AttributedHtmlView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 28/4/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//
import SwiftUI

struct HTMLTextAttributed: UIViewRepresentable {
    var text: String
    @Binding
    var dynamicHeight: CGFloat
    var width: CGFloat
    @Binding
    var urlForWebView: URL?
    var textSize: CGFloat = 17
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: textSize)
        textView.textColor = UIColor(Color("BlackTint"))
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.allowsEditingTextAttributes = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = .zero
        textView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 15, *) {
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        } else {
            textView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(Color("BlueLink"))
        ]
        textView.delegate = context.coordinator
        
        DispatchQueue.main.async {
            textView.setAttributedText(fromHtml: text)
            self.dynamicHeight = textView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
        }
        
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            uiView.textColor = UIColor(Color("BlackTint"))
        }
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator($urlForWebView)
    }
    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding
        var urlForWebView: URL?
        init(_ urlForWebView: Binding<URL?>) {
            self._urlForWebView = urlForWebView
        }
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            self.urlForWebView = URL
            return false
        }
    }
}

struct AttributedHtmlView: UIViewRepresentable {
    let html: String
    @Binding
    var dynamicHeight: CGFloat
    var width: CGFloat
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.allowsEditingTextAttributes = false
        textView.backgroundColor = UIColor.clear
        
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(Color("BlueLink")),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            uiView.attributedText = html.htmlToAttributedString
            uiView.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
            uiView.textColor = UIColor(Color("BlackTint"))
            uiView.backgroundColor = UIColor.clear
            dynamicHeight = uiView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
        }
    }
}
extension UITextView {
    /// Sets the label using the supplied html, using the label's font and font size as a basis.
    /// For predictable results, using only simple html without style sheets.
    /// See https://stackoverflow.com/questions/19921972/parsing-html-into-nsattributedtext-how-to-set-font
    ///
    /// - Returns: Whether the text could be converted.
    @discardableResult func setAttributedText(fromHtml html: String) -> Bool {
        guard let data = html.data(using: .utf8, allowLossyConversion: true) else {
            return false
        }

        do {
            let mutableText = try NSMutableAttributedString(
                data: data,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
            guard let font = font else { return false }
            mutableText.replaceFonts(with: font)
            self.attributedText = mutableText
            return true
        } catch {
            //print(">>> Could not create attributed text from \(html)\nError: \(error)")
            return false
        }
    }
}
extension NSMutableAttributedString {

    /// Replace any font with the specified font (including its pointSize) while still keeping
    /// all other attributes like bold, italics, spacing, etc.
    /// See https://stackoverflow.com/questions/19921972/parsing-html-into-nsattributedtext-how-to-set-font
    func replaceFonts(with font: UIFont) {
        let baseFontDescriptor = font.fontDescriptor
        var changes = [NSRange: UIFont]()
        enumerateAttribute(.font, in: NSMakeRange(0, length), options: []) { foundFont, range, _ in
            if let htmlTraits = (foundFont as? UIFont)?.fontDescriptor.symbolicTraits,
                let adjustedDescriptor = baseFontDescriptor.withSymbolicTraits(htmlTraits) {
                let newFont = UIFont(descriptor: adjustedDescriptor, size: font.pointSize)
                changes[range] = newFont
            }
        }
        changes.forEach { range, newFont in
            removeAttribute(.font, range: range)
            addAttribute(.font, value: newFont, range: range)
        }
    }
}
