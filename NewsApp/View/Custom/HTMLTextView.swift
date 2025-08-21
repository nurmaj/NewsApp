//
//  HTMLTextView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 4/5/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct HTMLTextView: View {
    var text: String
    let loadUrl: URL?
    let htmlType: NewsItem.TextType
    let tag: HTMLTag
    var parentTag: HTMLTag?
    var width: CGFloat
    @Binding
    var urlForWebView: URL?
    var loadUrlOnce: Bool = false
    var navActionHandler: (URL) -> Void = { _ in }
    var textSize: CGFloat = 17
    @State
    private var textHeight: CGFloat = .zero
    var body: some View {
        if htmlType == .html {
            HTMLDataWebView(viewModel: DataWebViewModel(with: !text.isEmpty ? text : nil, or: loadUrl, dataMime: nil, loadOnce: loadUrlOnce, onNavAction: navActionHandler), dynamicHeight: $textHeight, width: width)
                .frame(minHeight: textHeight)
        } else {
            switch tag {
            case .horizontalLine:
                CustomDivider(color: Color("BlackTint"))
                    .padding(.horizontal, 10)
            default:
                HTMLTextAttributed(text: text, dynamicHeight: $textHeight, width: width - 20 - (tagIsListItem() ? 24 : 0), urlForWebView: $urlForWebView, textSize: textSize)
                    .frame(minHeight: max(textHeight, 40))
                    .padding(.horizontal, 10)
                    .padding(.leading, tag == .listItem ? 6 : .zero)
                    .padding(.leading, tag == .listItem && parentTag == .ol ? 4 : .zero)
                    .overlay(tagIsListItem() ?
                         Circle().fill(Color("BlackTint"))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                            : nil, alignment: .topLeading)
                    .padding(.leading, tagIsListItem() ? 24 : .zero)
            }
        }
    }
    private func tagIsListItem() -> Bool {
        return tag == .listItem && parentTag != .ol
    }
}
struct HTMLTextView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLTextView(text: "Lorem ipsum dolor sit amet", loadUrl: nil, htmlType: .text, tag: .listItem, width: 390, urlForWebView: .constant(nil))
    }
}
