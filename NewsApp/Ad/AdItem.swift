//
//  AdItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 12/2/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct AdItem: Identifiable {
    let id: String
    let hashId: String
    let target: AdTarget
    let url: URL
    let bannerId: Int
    let bannerPath: String
    let bannerPathLandscape: String?
    
    let bgColor: String?
    let width: Int
    let height: Int
    let aspectRatio: Double
    let closeIcPath: String?
    
    //var timestamp: Int
    let showedTime: String
    let adIds: String
    let size: BannerSize
    let type: MediaType
    let scaleMode: DisplayMode?
    let linkType: LinkType?
    
    let skipTime: Int?
    // Non-backend key. For Ad Banner View state
    var displayState: AdState?
}

extension AdItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id="ad_id", target, url, bannerId="banner_id", bannerPath="banner_path", bannerPathLandscape="landscape_banner_path", bgColor="bg_color", width, height, aspectRatio="aspect_ratio", closeIcPath="close_icon", showedTime="showed_ad_time", adIds="ad_ids", size, type, scaleMode="scale_type", linkType="open_type", skipTime="skip_time"
    }
    enum BannerSize: Int, Decodable {
        case NONE = -1
        case FULLSCREEN = 1 // 468x750
        case M_FULLSCREEN = 2 // 468x800
        case X_FULLSCREEN = 3 // 468x854
        case FLOAT_BOTTOM = 4 // 468x90
        case SIZE_FEED = 5 // 468x120
    }
    enum MediaType: String, Decodable {
        case jpeg, jpg, png, gif
    }
    enum DisplayMode: Int, Decodable {
        case fitCenter = 0, fitStart = 1, fitEnd = 2, fitXY = 3, center = 4, centerCrop = 5, centerInside = 6, matrix = 7
    }
    enum LinkType: Int, Decodable {
        case link = 1, newsItem = 2
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        hashId = UUID().uuidString
        target = try values.decode(AdTarget.self, forKey: .target)
        url = try values.decode(URL.self, forKey: .url)
        do {
            bannerId = try Int(values.decode(String.self, forKey: .bannerId)) ?? .zero
        } catch DecodingError.typeMismatch {
            bannerId = try values.decode(Int.self, forKey: .bannerId)
        }
        bannerPath = try values.decode(String.self, forKey: .bannerPath)
        bannerPathLandscape = try values.decodeIfPresent(String.self, forKey: .bannerPathLandscape)
        bgColor = try values.decodeIfPresent(String.self, forKey: .bgColor)
        do {
            width = try Int(values.decode(String.self, forKey: .width)) ?? .zero
        } catch DecodingError.typeMismatch {
            width = try values.decode(Int.self, forKey: .width)
        }
        do {
            height = try Int(values.decode(String.self, forKey: .height)) ?? .zero
        } catch DecodingError.typeMismatch {
            height = try values.decode(Int.self, forKey: .height)
        }
        aspectRatio = try values.decode(Double.self, forKey: .aspectRatio)
        closeIcPath = try values.decodeIfPresent(String.self, forKey: .closeIcPath)
        showedTime = try values.decode(String.self, forKey: .showedTime)
        adIds = try values.decode(String.self, forKey: .adIds)
        size = try values.decode(BannerSize.self, forKey: .size)
        type = try values.decode(MediaType.self, forKey: .type)
        scaleMode = try values.decodeIfPresent(DisplayMode.self, forKey: .scaleMode)
        do {
            linkType = try values.decodeIfPresent(LinkType.self, forKey: .linkType)
        } catch DecodingError.typeMismatch {
            let linkType = try Int(values.decodeIfPresent(String.self, forKey: .linkType) ?? "0")
            self.linkType = LinkType(rawValue: linkType ?? 0)
        }
        skipTime = try values.decodeIfPresent(Int.self, forKey: .skipTime)
        self.displayState = .notReady
    }
}
extension AdItem: Hashable {
    static func == (lhs: AdItem, rhs: AdItem) -> Bool {
            return
                lhs.id == rhs.id &&
                lhs.hashId == rhs.hashId &&
                lhs.target == rhs.target &&
                lhs.url == rhs.url &&
                lhs.bannerId == rhs.bannerId &&
                lhs.bannerPath == rhs.bannerPath &&
                lhs.bannerPathLandscape == rhs.bannerPathLandscape &&
                lhs.bgColor == rhs.bgColor &&
                lhs.width == rhs.width &&
                lhs.height == rhs.height &&
                lhs.aspectRatio == rhs.aspectRatio &&
                lhs.closeIcPath == rhs.closeIcPath &&
                lhs.showedTime == rhs.showedTime &&
                lhs.adIds == rhs.adIds &&
                lhs.size == rhs.size &&
                lhs.type == rhs.type &&
                lhs.scaleMode == rhs.scaleMode &&
                lhs.linkType == rhs.linkType &&
                lhs.skipTime == rhs.skipTime
        }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(hashId)
        hasher.combine(target)
        hasher.combine(url)
        hasher.combine(bannerId)
        hasher.combine(bannerPath)
        hasher.combine(bannerPathLandscape)
        hasher.combine(bgColor)
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(aspectRatio)
        hasher.combine(closeIcPath)
        hasher.combine(showedTime)
        hasher.combine(adIds)
        hasher.combine(size)
        hasher.combine(type)
        hasher.combine(scaleMode)
        hasher.combine(linkType)
        hasher.combine(skipTime)
    }
}
extension AdItem {
    func getIDTokenString(with prefix: String) -> String {
        "AD_\(target)_\(prefix)_\(hashId)"
    }
}
struct AdResponse {
    var adItems: [AdTarget: AdItem]
}
extension AdResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case adItems
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        self.adItems = [AdTarget: AdItem]()
        do {
            let adDict = try? values.decode([String: AdItem].self)
            if let adItems = adDict {
                for (stringKey, value) in adItems {
                    guard let key = AdTarget(rawValue: Int(stringKey)!) else {
                        throw DecodingError.dataCorruptedError(in: values, debugDescription: "Invalid JSON Data")
                    }
                    self.adItems[key] = value
                }
            }
        } catch {
            print("AdResponse Error: \(error)")
        }
    }
}
struct AdTargetParams: Codable {
    var ids: String
    var time: String
    enum CodingKeys: String, CodingKey {
        case ids="ad_ids", time="showed_ad_time"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ids, forKey: .ids)
        try container.encode(time, forKey: .time)
    }
}
enum AdState {
    case notReady, readyToShow, showed, closed
}
enum AdTarget: Int, Codable {
    case fullscreenFeed = 1, fullscreenDetail = 2, bottomFeed = 3, bottomDetail = 4, topAllPage = 5, insideFeedItems = 6, insideDetailTextItems = 7, noTarget = -1
}
enum AdClosePlace: Int {
    case closeIcon=1,timerEnd=2,onBannerClick=3,loadFailed=4
}
struct AdDefaults {
    static let PNID = "0_0"
    static let IDs = "0"
    static let TIME = ":0"
    static let EMPTY_JSON = "{}"
    static let EMPTY_JSON_ARR = "[]"
    static let DEFAULT_SKIP_TIMEOUT: Int = 9
}
