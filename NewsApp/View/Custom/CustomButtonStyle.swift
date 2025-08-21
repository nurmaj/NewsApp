//
//  CustomButtonStyle.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 13/6/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct StrokeCapsule: ButtonStyle {
    let color: Color = Color("GreyLightMono")
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            //.border(configuration.isPressed ? Color("GreyLightMono") : Color.clear)
            .overlay( configuration.isPressed ?
                  Capsule()
                    .stroke(color, lineWidth: 1.0)
                : nil
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StrokeRoundedRect: ButtonStyle {
    var cornerRadius = CGFloat.zero
    let color: Color = Color("GreyLightMono")
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            //.border(configuration.isPressed ? Color("GreyLightMono") : Color.clear)
            .overlay( configuration.isPressed ?
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: 1.0)
                : nil
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StrokeCircle: ButtonStyle {
    let color: Color = Color("GreyLightMono")
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            //.border(configuration.isPressed ? Color("GreyLightMono") : Color.clear)
            .overlay( configuration.isPressed ?
                  Circle()
                    .stroke(color, lineWidth: 1.0)
                : nil
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
