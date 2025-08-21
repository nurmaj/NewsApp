//
//  Media.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 2/3/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct Media {
    enum FileFormat: String, Decodable {
        case jpg, png, gif, mp4, mov
    }
    enum Layout: String, Decodable {
        case landscape, square, portrait
    }
}
struct ImageItem {
    let id: String
    let title, author, name: String?
    let thumb: URL
    let sd, hd, sensitive: URL?
    let width, height: Int?
}
struct Embed {
    let id: String
    let source: SourceType
    var url, thumb: URL?
    let path: MediaPath?
    let title, name: String?
    let format: Media.FileFormat?
    let width, height: Int?
    let sensitive: Bool?
}
struct MediaPath {
    let thumb: URL?
    let sd: URL?
    let hd: URL?
}
struct DetailMedia: Hashable {
    let placeholderImage: UIImage?
    let embed: Embed?
    let image: ImageItem?
}
extension Embed: Hashable {
    static func == (lhs: Embed, rhs: Embed) -> Bool {
        return lhs.source == rhs.source &&
            lhs.url == rhs.url &&
            lhs.thumb == rhs.thumb &&
            lhs.path == rhs.path &&
            lhs.title?.count == rhs.title?.count &&
            lhs.name == rhs.name &&
            lhs.format == rhs.format &&
            lhs.width == rhs.width &&
            lhs.height == rhs.height &&
            lhs.sensitive == rhs.sensitive
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(url)
        hasher.combine(thumb)
        hasher.combine(path)
        hasher.combine(title?.count)
        hasher.combine(name)
        hasher.combine(format)
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(sensitive)
    }
}
extension ImageItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, author, name, thumb, sd, hd, sensitive, width, height
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(values.decodeIfPresent(Int.self, forKey: .id) ?? 0)
        } catch DecodingError.typeMismatch {
            id = try values.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        }
        
        title = try values.decodeIfPresent(String.self, forKey: .title)
        author = try values.decodeIfPresent(String.self, forKey: .author)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        thumb = try values.decode(URL.self, forKey: .thumb)
        sd = try values.decodeIfPresent(URL.self, forKey: .sd)
        hd = try values.decodeIfPresent(URL.self, forKey: .hd)
        sensitive = try values.decodeIfPresent(URL.self, forKey: .sensitive)
        width = try values.decodeIfPresent(Int.self, forKey: .width)
        height = try values.decodeIfPresent(Int.self, forKey: .height)
    }
    func getHd(showSensitive: Bool = false, forceHD: Bool = false) -> URL {
        if showSensitive && sensitive != nil {
            return sensitive!
        } else if hd != nil && (forceHD || !Preference.bool(.dataSaver)) {
            return hd!
        } else if sd != nil {
            return sd!
        }
        return thumb
    }
}

extension Embed: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, source, url, thumb="thumbnail_url", path, title, format, name, width, height, sensitive
    }
    enum AlternateCodingKeys: String, CodingKey {
        case watch, mq, defaultThumb="default", thumbUrl="thumb_url", thumb240="thumb240p"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let alternateValues = try decoder.container(keyedBy: AlternateCodingKeys.self)
        do {
            id = try String(values.decodeIfPresent(Int.self, forKey: .id) ?? 0)
        } catch DecodingError.typeMismatch {
            id = try values.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        }
        source = try values.decode(SourceType.self, forKey: .source)
        do {
            url = try values.decode(URL.self, forKey: .url)
        } catch DecodingError.keyNotFound {
            if alternateValues.contains(.watch) {
                url = try alternateValues.decodeIfPresent(URL.self, forKey: .watch)
            }/* else if alternateValues.contains(.path) {
                url = try alternateValues.decodeIfPresent(URL.self, forKey: .path)
            }*/
        }
        do {
            thumb = try values.decode(URL.self, forKey: .thumb)
        } catch DecodingError.keyNotFound {
            if alternateValues.contains(.mq) {
                thumb = try alternateValues.decodeIfPresent(URL.self, forKey: .mq)
            } else if alternateValues.contains(.defaultThumb) {
                thumb = try alternateValues.decodeIfPresent(URL.self, forKey: .defaultThumb)
            } else if alternateValues.contains(.thumbUrl) {
                thumb = try alternateValues.decodeIfPresent(URL.self, forKey: .thumbUrl)
            } else if alternateValues.contains(.thumb240) {
                thumb = try alternateValues.decodeIfPresent(URL.self, forKey: .thumb240)
            }
        }
        /*if values.contains(.url) {
            url = try values.decodeIfPresent(URL.self, forKey: .url)
        } else*/
        path = try values.decodeIfPresent(MediaPath.self, forKey: .path)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        format = try values.decodeIfPresent(Media.FileFormat.self, forKey: .format)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        do {
            width = try Int(values.decodeIfPresent(String.self, forKey: .width) ?? "0")
        } catch DecodingError.typeMismatch {
            width = try values.decodeIfPresent(Int.self, forKey: .width)
        }
        do {
            height = try Int(values.decodeIfPresent(String.self, forKey: .height) ?? "0")
        } catch DecodingError.typeMismatch {
            height = try values.decodeIfPresent(Int.self, forKey: .height)
        }
        sensitive = try values.decodeIfPresent(Bool.self, forKey: .sensitive)
    }
    enum SourceType: String, Decodable {
        case bulbul, instagram, facebook, tiktok, youtube, twitter, telegram, other
    }
    func getRect() -> CGSize {
        if width != nil && height != nil {
            return CGSize(width: width ?? .zero, height: height ?? .zero)
        }
        return .zero
    }
}
extension ImageItem: Hashable {
    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title?.count == rhs.title?.count &&
            lhs.author == rhs.author &&
            lhs.name == rhs.name &&
            lhs.thumb == rhs.thumb &&
            lhs.sd == rhs.sd &&
            lhs.sensitive == rhs.sensitive &&
            lhs.width == rhs.width &&
            lhs.height == rhs.height
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title?.count)
        hasher.combine(author)
        hasher.combine(name)
        hasher.combine(thumb)
        hasher.combine(sd)
        hasher.combine(hd)
        hasher.combine(sensitive)
        hasher.combine(width)
        hasher.combine(height)
    }
}
extension MediaPath: Hashable {
    static func == (lhs: MediaPath, rhs: MediaPath) -> Bool {
        return lhs.thumb == rhs.thumb &&
            lhs.sd == rhs.sd &&
            lhs.hd == rhs.hd
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(thumb)
        hasher.combine(sd)
        hasher.combine(hd)
    }
}
extension MediaPath: Decodable {
    enum CodingKeys: String, CodingKey {
        case thumb, sd, hd
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        thumb = try values.decodeIfPresent(URL.self, forKey: .thumb)
        sd = try values.decodeIfPresent(URL.self, forKey: .sd)
        hd = try values.decodeIfPresent(URL.self, forKey: .hd)
    }
    /*func getHDPath() -> URL? {
        if let hd = self.hd {
            return hd
        } else if let sd = self.sd {
            return sd
        }
        return thumb
    }*/
}
