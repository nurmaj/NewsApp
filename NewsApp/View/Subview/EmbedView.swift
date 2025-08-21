//
//  EmbedView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 27/8/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct EmbedView: View {
    @EnvironmentObject
    var detailVM: DetailViewModel
    let parentId: String
    var embed: Embed
    let vertAlignment: Alignment
    let onShowPlayer: (DetailMedia) -> ()
    @State
    private var contentHeight: CGFloat = .zero
    /*@State
    private var showVideoPlayer = false*/
    @State
    private var posterImage: UIImage?
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                if let thumb = embed.thumb {
                    Color.black
                        .frame(width: getLessWidth(geo.size.width), height: contentHeight)
                        .overlay( detailVM.isEmbedDetailed(embed: embed.id) ? nil :
                            AsyncImage(url: thumb, placeholder: {
                                Color("GreyBg")
                                    .aspectRatio(DefaultAppConfig.projectAspectRatio, contentMode: .fill)
                            }, failure: { Spacer() }) { (state, uiImage) in
                                self.posterImage = uiImage
                            }
                                .aspectRatio(contentMode: .fit)
                        )
                        .overlay(
                            EmbedIconView(source: embed.source, sourceName: embed.name ?? "")
                            , alignment: getIconAlign()
                        )
                        .overlay(
                            embed.source == .bulbul ? EmbedExtraIcon(source: embed.source, embedUrl: embed.url) : nil
                            , alignment: .bottomLeading
                        )
                } else {
                    Rectangle()
                        .fill(Color("GreyBg"))
                        .frame(width: getLessWidth(geo.size.width), height: contentHeight)
                        .overlay(
                            EmbedIconView(source: embed.source, sourceName: embed.name ?? "")
                            , alignment: getIconAlign()
                        )
                        .overlay(
                            embed.source == .bulbul ? EmbedExtraIcon(source: embed.source, embedUrl: embed.url) : nil
                            , alignment: .bottomLeading
                        )
                    if embed.source != .youtube && embed.source != .bulbul {
                        Text("tap_to_see")
                            .foregroundColor(Color("GreyDark"))
                            .font(.subheadline)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .background(Color("GreyLight"))
                    }
                }
            }
            .onAppear {
                self.contentHeight = getLessWidth(geo.size.width) / DefaultAppConfig.projectAspectRatio
            }
            .frame(maxHeight: .infinity, alignment: vertAlignment)
            .onTapGesture {
                if embed.source == .bulbul {
                    onShowPlayer(DetailMedia(placeholderImage: posterImage, embed: embed, image: nil))
                } else if let embedUrl = embed.url, UIApplication.shared.canOpenURL(embedUrl) {
                    UIApplication.shared.open(embedUrl)
                }
            }
        }
        .frame(minHeight: contentHeight)
    }
    func getIconAlign() -> Alignment {
        if embed.source == .youtube || embed.source == .bulbul {
            return .center
        }
        return .bottomTrailing
    }
    private func getLessWidth(_ geoW: CGFloat) -> CGFloat {
        return min(geoW, min(getRect().width, getRect().height))
    }
}
struct EmbedIconView: View {
    let source: Embed.SourceType
    let sourceName: String
    var body: some View {
        if source == .other {
            Text(sourceName)
                .font(.subheadline)
                .foregroundColor(Color("BlackTint"))
                .padding(.trailing, 10)
                .padding(.bottom, 10)
        } else if source == .bulbul {
            getBGColor()
                .frame(width: 54, height: 54)
                .cornerRadius(7)
                .overlay(
                    Image(systemName: "play.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: getIcWH(), height: getIcWH())
                        .foregroundColor(Color.white)
                )
        } else {
            getBGColor()
                .padding(.all, getIcPadding(edge: .all))
                .padding(.leading, getIcPadding(edge: .leading))
                .padding(.bottom, getIcPadding(edge: .bottom))
                .padding(.trailing, getIcPadding(edge: .trailing))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(source.rawValue)
                        .resizable()
                        .scaledToFill()
                        .frame(width: getIcWH(), height: getIcWH())
                    , alignment: getIcAlign()
                )
        }
    }
    func getBGColor() -> Color {
        if source == .twitter || source == .telegram {
            return Color.clear
        } else if source == .bulbul {
            return Color("PrimaryColor").opacity(0.6)
        }
        return Color.white
    }
    func getIcAlign() -> Alignment {
        if source == .youtube {
            return .center
        }
        return .topLeading
    }
    func getIcWH() -> CGFloat {
        if source == .youtube {
            return 48
        } else if source == .bulbul {
            return 24
        }
        return 40
    }
    func getIcPadding(edge: Edge.Set = .all) -> CGFloat {
        if edge == .leading && source != .facebook || source == .twitter {
            return .zero
        }
        if source == .youtube && edge == .all {
            return 14
        } else if source == .tiktok {
            return edge == .all ? 10 : 8
        } else if source == .instagram {
            return edge == .all ? 6 : 8
        } else if source == .facebook {
            return edge == .bottom || edge == .leading ? 3 : 10
        }
        return .zero
    }
}
struct EmbedExtraIcon: View {
    let source: Embed.SourceType
    let embedUrl: URL?
    var body: some View {
        Text("bulbul")
            .font(.system(size: 16))
            .fontWeight(.heavy)
            .foregroundColor(.white)
            .padding(.all, 10)
            .background(Color.black.opacity(0.5).cornerRadius(2))
            .onTapGesture {
                if let embedSourceUrl = embedUrl, UIApplication.shared.canOpenURL(embedSourceUrl) {
                    UIApplication.shared.open(embedSourceUrl)
                }
            }
    }
}
struct EmbedView_Previews: PreviewProvider {
    static var previews: some View {
        EmbedView(parentId: "10_112376", embed: Embed(id: "1", source: .bulbul, url: nil, thumb: URL(string: "http://static.bulbul.kg/img/2/79622.8fee0f8ba55e79088124ca629cb9721a.1.240.jpg"), path: nil, title: nil, name: nil, format: nil, width: nil, height: nil, sensitive: false), vertAlignment: .center, onShowPlayer: { _ in })
    }
}
