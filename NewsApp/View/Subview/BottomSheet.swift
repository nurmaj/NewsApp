//
//  BottomSheet.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 8/9/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    @Binding
    var showSheet: Bool
    var title: LocalizedStringKey
    var content: Content
    init(showSheet: Binding<Bool>, title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self._showSheet = showSheet
        self.title = title
        self.content = content()
    }
    @State
    var dragOffset: CGFloat = .zero
    @State
    var contentHeight: CGFloat = .zero
    /*@State
    private var debug: String = ""*/
    var body: some View {
        VStack(spacing: 0) {
            Color.clear
            ZStack {
                Color("GreyBg")
                    .padding(.top, 120)
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color("GreyLight"))
                        .frame(width: 50, height: 6)
                        .padding(.top, 8)
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("BlackTint"))
                        .padding(.horizontal, 10)
                        .padding(.top, 14)
                        .padding(.bottom, 8)
                    /*Text("DEBUG: \(debug)")
                        .font(.system(size: 12))*/
                    Rectangle()
                        .fill(Color("GreyLight"))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                    //ScrollView(.vertical, showsIndicators: false) {
                    ZStack {
                        content
                    }
                    .frame(maxWidth: .infinity)
                }
                //.frame(width: 300)
                .background(Color("GreyBg"))
                //.cornerRadius(50)
                .cornerRadius(25, corners: .topLeft)
                .cornerRadius(25, corners: .topRight)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged() { value in
                            let offsetY = value.translation.height
                            if offsetY < 0 && offsetY < -80 {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    dragOffset = 0
                                }
                            } else if offsetY > 70 {
                                withAnimation(.spring()) {
                                    dragOffset = contentHeight
                                    showSheet = false
                                }
                            } else {
                                dragOffset = offsetY
                            }
                            //debug = "\(offsetY)"
                        }
                        .onEnded() { value in
                            //debug = "\(value.translation.height)"
                            withAnimation() {
                                dragOffset = 0
                            }
                        }
                )
            }
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear() {
                            contentHeight = geo.size.height
                            //debug = "\(contentHeight)"
                        }
                }
            )
            //.layoutPriority(1)
        }
        //.frame(maxWidth: .infinity)
        .ignoresSafeArea()
        .background(
            Color.black.opacity(showSheet ? 0.4 : 0).ignoresSafeArea()
                .onTapGesture {
                    withAnimation() {
                        showSheet = false
                    }
                })
        //.transition(.move(edge: .bottom))
    }
}

struct BottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheet(showSheet: .constant(true), title: "why_covered") {
            WhySensitive()
        }
        //.preferredColorScheme(.dark)
    }
}
