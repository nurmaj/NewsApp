//
//  TopBarView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 27/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct TopBarView<Leading: View, Trailing: View>: View {
    @ViewBuilder
    let leadingBtn: Leading
    let logo: Bool
    var title: String?
    @ViewBuilder
    let trailingBtn: Trailing
    var bgColor = Color("WhiteBlackBg")
    @State
    private var navBarTopInset = CGFloat.zero
    @State
    private var isHorizontal = false
    var body: some View {
        VStack {
            Spacer(minLength: .zero)
            HStack(spacing: .zero) {
                leadingBtn
                Spacer(minLength: 0)
                trailingBtn
            }
            .padding(.horizontal, 12)
            .frame(height: DefaultAppConfig.appNavBarHeight)
            .overlay(
                ZStack {
                    if logo {
                        Spacer(minLength: 0)
                        Image("AppLogo")
                            .renderingMode(.template)
                            .foregroundColor(Color("PrimaryTint"))
                    } else if let title = self.title {
                        Spacer(minLength: 0)
                        Text(LocalizedStringKey(title))
                            .lineLimit(1)
                            .font(.body)
                            .foregroundColor(Color("BlackTint"))
                    }
                }
            )
        }
        .background(
            GeometryReader { geo in
                bgColor.edgesIgnoringSafeArea(.top)
                    .onAppear {
                        if UIDevice.current.orientation.isLandscape {
                            isHorizontal = true
                        }
                        if geo.safeAreaInsets.top == .zero {
                            setBarHeight(with: safeEdges?.top ?? .zero)
                        }
                    }
                    .onChange(of: geo.safeAreaInsets) { _ in
                        if isHorizontal {
                            setBarHeight(with: .zero)
                        } else if geo.safeAreaInsets.top == .zero {
                            setBarHeight(with: safeEdges?.top ?? .zero)
                        }
                    }
                    .onRotate { newOrientation in
                        isHorizontal = newOrientation == .landscapeLeft || newOrientation == .landscapeRight
                    }
             }
        )
        .frame(height: DefaultAppConfig.appNavBarHeight + self.navBarTopInset)
        .overlay(CustomDivider(color: Color("GreyWhite")), alignment: .bottom)
    }
    private func onTopBarAppear() {
        if UIDevice.current.orientation.isLandscape {
            isHorizontal = true
        }
    }
    private func setBarHeight(with topInset: CGFloat) {
        if topInset != navBarTopInset {
            self.navBarTopInset = topInset
        }
    }
}
struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopBarView(leadingBtn: {
            BackButtonView(onCloseTap: {})
        }, logo: true, trailingBtn: {
            Button {
                
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color("PrimaryTint"))
            }

        })
    }
}
