//
//  Modifiers.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 4/7/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct GlowBorder: ViewModifier {
    var color: Color
    var lineWidth: Int
    func body(content: Content) -> some View {
        applyShadow(content: AnyView(content), lineWidth: lineWidth)
    }
    func applyShadow(content: AnyView, lineWidth: Int) -> AnyView {
        if lineWidth > 0 {
            return applyShadow(content: AnyView(content.shadow(color: color, radius: 1)), lineWidth: lineWidth - 1)
        }
        return content
    }
}
struct TextFieldSubmitLabel {
    let submitLabel: TextFieldSubmitLabelType
    enum CompatibleSubmitLabel {
        case search, done, go, none
    }
}
@available(iOS 15.0, *)
extension TextFieldSubmitLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .submitLabel(getSubmitLabel())
    }
    private func getSubmitLabel() -> SubmitLabel {
        switch submitLabel {
        case .search:
            return .search
        case .done:
            return .done
        case .go:
            return .go
        default:
            return .return
        }
    }
}
typealias TextFieldSubmitLabelType = TextFieldSubmitLabel.CompatibleSubmitLabel
extension View {
    func glowBorder(color: Color, lineWidth: Int) -> some View {
        self.modifier(GlowBorder(color: color, lineWidth: lineWidth))
    }
    @ViewBuilder
    func submitLabeliOS15(_ label: TextFieldSubmitLabelType) -> some View {
        if label == .none {
            self
        } else {
            if #available(iOS 15, *) {
                self.modifier(TextFieldSubmitLabel(submitLabel: label))
            } else {
                self
            }
        }
    }
}
