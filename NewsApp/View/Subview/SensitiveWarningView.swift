//
//  SensitiveWarningView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 7/9/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct SensitiveWarningView: View {//<Cover: View>
    /*@State
    var seeContent: Bool = false*/
    //let sensitiveItem: TextItem
    @Binding
    var seeContent: Bool
    @State
    var seeWhy: Bool = false
    var contentType: SensitiveType
    var shortVersion: Bool
    //let cover: () -> Cover
    //let content: () -> Content
    var body: some View {
        if !seeContent {
            ZStack {
                //cover()
                //Spacer()
                /*Color("GreyDarker")
                    .blur(radius: 50)
                    .overlay(
                        Color.black
                            .opacity(0.3)
                    )*/
                //Color.clear
                    /*.background(BlurEffectView(style: .systemUltraThinMaterial))*/
                if shortVersion {
                    Image(systemName: "eye.slash")
                        .font(.largeTitle)
                        .foregroundColor(Color.white.opacity(0.8))
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        VStack {
                            Image(systemName: "eye.slash")
                                .font(.largeTitle)
                                .padding(.bottom, 8)
                                //.glowBorder(color: Color.black, lineWidth: 1)
                            Text("sensitive_content")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.bottom, 2)
                            Text(LocalizedStringKey("sensitive_"+contentType.rawValue+"_desc"))
                                //.font(.subheadline)
                                .font(.system(size: 16))
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    seeWhy.toggle()
                                }
                            }) {
                                Text("see_why")
                                    .font(.body)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1.0)
                                    )
                            }
                            .padding(.top, 12)
                        }
                        .padding(.horizontal, 6)
                        .padding(.top, 6)
                        //.padding(.bottom, 10)
                        Spacer()
                        CustomDivider(color: Color.white, opacity: 0.8)
                            .padding(.horizontal, 20)
                        Button(action: { seeContent.toggle() }) {
                            Text(LocalizedStringKey("see_"+contentType.rawValue))
                                .font(.system(size: 16, weight: .bold))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    }
                    .padding(.top, safeEdges?.top ?? 6)
                    .padding(.bottom, safeEdges?.bottom ?? 6)
                    .foregroundColor(Color.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.black.opacity(0.2)
                    //.scaleEffect(1.05, anchor: .leading)
                    //.frame(width: bgWidthWithPadding)
            )
            .ignoresSafeArea()
            .overlay(seeWhy ? BottomSheet(showSheet: $seeWhy, title: "why_covered") {
                WhySensitive()
            } : nil)
            
        }/* else {
            EmptyView()
        }*/
    }
}
struct SensitiveCoverView: View {
    let sensitiveItem: TextItem
    let frameSize: CGSize
    var body: some View {
        if let imageItem = sensitiveItem.image {
            AsyncImage(
                url: imageItem.hd ?? imageItem.thumb,
                placeholder: {
                    Color("GreyBg")
                        .aspectRatio(DefaultAppConfig.projectAspectRatio, contentMode: .fit)
                }, failure: { Spacer() }
                , completion: { (_, _) in }
            )
            .aspectRatio(contentMode: .fill)
            /*.overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 20)
                , alignment: .trailing
            )*/
            .scaleEffect(1.05)
            .blur(radius: 5)
            .frame(width: frameSize.width)
            //.scaleEffect(1.1)
        }
    }
}
/*struct BlurEffectView: UIViewRepresentable {
    //var effect: UIVisualEffect?
    var style: UIBlurEffect.Style = .dark
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))        
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}*/
struct WhySensitive: View {
    @State
    var htmlTextHeight: CGFloat = .zero
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.shield")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                WrapText(text: "why_covered_section1")
                    .font(.body)
            }
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "exclamationmark.bubble")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                WrapText(text: "why_covered_section2")
                    .font(.body)
            }
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "eye.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                WrapText(text: "why_covered_section3")
                    .font(.body)
            }
        }
        .padding(.all, 10)
        .foregroundColor(Color("BlackTint"))
    }
}

struct WrapText: View {
    var text: LocalizedStringKey
    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

enum SensitiveType: String {
    case photo, video, other
}

struct SensitiveWarningView_Previews: PreviewProvider {
    static var previews: some View {
        SensitiveWarningView(seeContent: .constant(false), contentType: .photo, shortVersion: false)
            //.preferredColorScheme(.dark)
        //WhySensitive()
    }
}
