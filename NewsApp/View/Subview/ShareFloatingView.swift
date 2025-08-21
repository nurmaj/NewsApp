//
//  ShareFloatingView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 6/7/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ShareFloatingView: View {
    let url: URL?
    let shareId: String
    let sharedCnt: String?
    let shareType: API.ShareType
    let onShare: (String) -> Void
    var disableSafeEdgeBottom: Bool = false
    var body: some View {
        if let shareUrl = self.url {
            ZStack {
                floatingButton(shareUrl)
                    .buttonStyle(StrokeRoundedRect(cornerRadius: 26))
                    .background(
                        //Capsule()
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color("PrimaryMono"))
                    )
                    .shadow(color: Color("PrimaryMono"), radius: 4)
            }
            .padding(.trailing, 15)
            .padding(.bottom, 15 + (!disableSafeEdgeBottom ? (safeEdges?.bottom ?? 4) : .zero))
        }
    }
    @ViewBuilder
    func floatingButton(_ shareUrl: URL) -> some View {
        if #available(iOS 16, *) {
            ShareLink(item: shareUrl) {
                floatingContent
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        onShareTapEvent(shareUrl)
                    }
            )
        } else {
            Button(action: {
                //shareSheetPresented.toggle()
                shareUrl.shareSheet()
                onShareTapEvent(shareUrl)
            }) {
                floatingContent
            }
        }
    }
    var floatingContent: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .top) {
                Text("share")
                    .font(.system(size: 13))
                    .padding(.top, 30)
                Image("share")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            }
            if let sharedCnt = sharedCnt, sharedCnt != "0", sharedCnt != "" {
                Text("\(sharedCnt)")
                    .font(.system(size: 12))
                    .padding(.top, 2)
                    .padding(.bottom, 2)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        //.padding(.bottom, 6)
    }
    private func onShareTapEvent(_ shareUrl: URL) {
        self.onShare(shareUrl.absoluteString)
        FAnalyticsService.shared.sendLogEvent(id: "\(shareType.rawValue)_\(shareId)", title: shareUrl.absoluteString, type: "share")
    }
}
struct ShareFloatingView_Previews: PreviewProvider {
    static var previews: some View {
        ShareFloatingView(url: nil, shareId: "id-0", sharedCnt: "1", shareType: .newsItem, onShare: { _ in })
            .preferredColorScheme(.dark)
    }
}
