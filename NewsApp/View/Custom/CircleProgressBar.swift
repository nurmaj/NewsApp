//
//  CircleProgressBar.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 14/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct CircleProgressBar: View {
    @State
    private var rotationDegree: Double = .zero
    var color: Color = Color.white
    //var color: Color = Color.black
    var lineWidth: CGFloat = 4
    var widthHeight: CGFloat = .infinity
    var animDuration: Double = 1
    var cancellable = false
    var onCancel: (() -> ())?
    var body: some View {
        ZStack {
            if cancellable {
                Circle()
                    .fill(Color.black.opacity(0.6))
            }
            Circle()
                .trim(from: 0, to: 0.8)
                //.stroke(StrokeStyle(lineWidth: 20, lineCap: .butt, lineJoin: .bevel))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: rotationDegree))
                //.rotationEffect(.degrees(0))
                .foregroundColor(color)
                .animation(Animation.linear(duration: animDuration).repeatForever(autoreverses: false))
                .onAppear {
                    self.rotationDegree = 360
                }
                .padding(.all, 4)
                //.background(withBg ? Circle().fill(Color.black.opacity(0.2)) : nil)
            if cancellable {
                Button(action: {
                    onCancel?()
                }, label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .semibold))
                        /*.resizable()
                        .aspectRatio(contentMode: .fit)*/
                        .foregroundColor(.white)
                        //.frame(minWidth: 12, maxWidth: 32, minHeight: 12, maxHeight: 32)
                        //.frame(minWidth: 12, maxWidth: 18, minHeight: 12, maxHeight: 18, alignment: .center)
                })
            }
        }
        .frame(maxWidth: widthHeight, maxHeight: widthHeight)
    }
}

struct CircleProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgressBar(widthHeight: 54, cancellable: true)
    }
}
