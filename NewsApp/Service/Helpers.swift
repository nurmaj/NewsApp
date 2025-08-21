//
//  Helpers.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 17/2/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Combine

extension Int {
    func toFormattedDate(showTodayLabel: Bool = false) -> String {
        let timeInterval = TimeInterval(self)
        let date = Date(timeIntervalSince1970: timeInterval)
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        if calendar.isDateInYesterday(date) {
            dateFormatter.dateFormat = "Вчера в HH:mm"
        } else if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = (showTodayLabel ? "Сегодня в " : "") + "HH:mm"
        } else {
            dateFormatter.dateFormat = "HH:mm, dd-MM-yy"
        }
        return dateFormatter.string(from:date)
    }
}
extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        return self?.isEmpty ?? true
    }

}
extension String {
    func setHTMLFromString(font: UIFont) -> NSAttributedString? {
        let modifiedFont = String(format:"<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: \(font.pointSize)\">%@</span>", self)
        
        guard let data = modifiedFont.data(using: .utf8) else { return nil }

        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
            return attributedString
        } else {
            return NSAttributedString()
        }
    }
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    var base64Decoded: String {
        Data(self.utf8).base64EncodedString()
    }
    var dateFromISO8601: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        return dateFormatter.date(from: self)
    }
    func isoDateExpired() -> Bool {
        guard let dateFromISO8601 = dateFromISO8601 else {
            return true
        }
        
        return dateFromISO8601 < Date()
    }
    func getSubString(maxLength: Int = .zero) -> String {
        if maxLength > 0 && self.count >= maxLength {
            let toIndex = self.index(self.startIndex, offsetBy: maxLength)
            return String(self[..<toIndex])
        }
        return self
    }
}

extension View {
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
    var safeEdges: UIEdgeInsets? {
        return UIApplication.shared.windows.first?.safeAreaInsets
    }
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
    func isHorizontal(_ value: Bool) -> some View {
        environment(\.isHorizontal, value)
    }
}
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}
struct AnimationFinished: AnimatableModifier {
    let targetValue: CGFloat
    let completion: () -> ()
    var animatableData: CGFloat {
        didSet {
            didComplete()
        }
    }
    init(of value: CGFloat, completion: @escaping () -> ()) {
        self.animatableData = value
        self.targetValue = value
        self.completion = completion
    }
    func body(content: Content) -> some View {
        content
    }
    private func didComplete() {
        if animatableData == targetValue {
            DispatchQueue.main.async {
                self.completion()
            }
        }
    }
}
extension UIView {
    /// Remove all subview
    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

    /// Remove all subview with specific type
    func removeAllSubviews<T: UIView>(type: T.Type) {
        subviews
            .filter { $0.isMember(of: type) }
            .forEach { $0.removeFromSuperview() }
    }
}
extension URL {
    var hostName: String? {
        guard let hostName = host else {
            return self.absoluteString
        }
        if let firstIndex = hostName.firstIndex(of: ".") {
            if hostName[..<firstIndex] == "www" {
                return String(hostName.dropFirst(4))
            }
        }
        return host?.components(separatedBy: ".").suffix(3).joined(separator: ".")
        //return host?.components(separatedBy: ".").suffix(2).joined(separator: ".")
    }
    func shareSheet() {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            let activityVC = UIActivityViewController(activityItems: [self], applicationActivities: nil)
            topController.present(activityVC, animated: true, completion: nil)
        }
    }
    func appendQuery(_ queryItem: String, value: String?) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: queryItem, value: value))
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
}
extension CGFloat {
    var opacityProgress: Double {
        let halfHeight = UIScreen.main.bounds.height / 2
        let progress = abs(self / halfHeight)
        return Double(1 - progress)
    }
    
}
extension CGSize {
    var dragCloseOffset: CGFloat? {
        if width == .zero || height == .zero {
            return nil
        }
        let aspRatioHeight = width / DefaultAppConfig.projectAspectRatio
        return (((height - aspRatioHeight)/2)/100)*75
    }
}
extension Date {
    static var currentTimeStamp: Int64 {
        return Int64(Date().timeIntervalSince1970/* * 1000*/)
    }
}
extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
extension Bundle {
    public var appName: String { getInfo("CFBundleName")  }
    public var displayName: String {getInfo("CFBundleDisplayName")}
    public var appBuild: String { getInfo("CFBundleVersion") }
    public var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "" }
}
extension UIDevice {
    var deviceIdiom: String {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return "iPhone"
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return "iPad"
        } else if UIDevice.current.userInterfaceIdiom == .tv {
            return "TV"
        } else if UIDevice.current.userInterfaceIdiom == .carPlay {
            return "CarPlay"
        }
        return "N/A"
    }
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
extension Int64 {
    var byteSize: String {
        return ByteCountFormatter().string(fromByteCount: self)
    }
}
extension Color {
    init(hex string: String) {
        var string: String = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }

        // Double the last value if incomplete hex
        if !string.count.isMultiple(of: 2), let last = string.last {
            string.append(last)
        }

        // Fix invalid values
        if string.count > 8 {
            string = String(string.prefix(8))
        }

        // Scanner creation
        let scanner = Scanner(string: string)

        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        if string.count == 2 {
            let mask = 0xFF

            let g = Int(color) & mask

            let gray = Double(g) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)

        } else if string.count == 4 {
            let mask = 0x00FF

            let g = Int(color >> 8) & mask
            let a = Int(color) & mask

            let gray = Double(g) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)

        } else if string.count == 6 {
            let mask = 0x0000FF
            let r = Int(color >> 16) & mask
            let g = Int(color >> 8) & mask
            let b = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)

        } else if string.count == 8 {
            let mask = 0x000000FF
            let r = Int(color >> 24) & mask
            let g = Int(color >> 16) & mask
            let b = Int(color >> 8) & mask
            let a = Int(color) & mask

            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0
            let alpha = Double(a) / 255.0

            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)

        } else {
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        }
    }
}
extension FileManager {
    func systemFreeSize() -> String? {
        do {
            let attrs = try attributesOfFileSystem(forPath: NSHomeDirectory())
            guard let freeSize = attrs[.systemFreeSize] as? Int64 else {
                return nil
            }
            return freeSize.byteSize
        } catch {
            return nil
        }
    }
    func systemTotalSizeBytes() -> String? {
        do {
            let attrs = try attributesOfFileSystem(forPath: NSHomeDirectory())
            guard let size = attrs[.systemSize] as? Int64 else {
                return nil
            }
            return size.byteSize
        } catch {
            return nil
        }
    }
}
extension Encodable {
    func toEncodedData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
extension Array where Element: Hashable {
    func nextEl(after: Element, infinite: Bool) -> Element? {
        if let index = self.firstIndex(of: after), index + 1 < self.count {
            return self[index + 1]
        }
        return infinite ? self[0] : nil
    }
    func prevEl(before: Element, infinite: Bool) -> Element? {
        if let index = self.firstIndex(of: before), index - 1 >= 0 {
            return self[index - 1]
        }
        return infinite ? self[self.count - 1] : nil
    }
}
private struct HorizontalLayoutKey: EnvironmentKey {
    static let defaultValue: Bool = false
}
extension EnvironmentValues {
    var isHorizontal: Bool {
        get { self[HorizontalLayoutKey.self] }
        set { self[HorizontalLayoutKey.self] = newValue }
    }
}

enum FromPoint: String {
    case inited, top, bottom, refresh, retry, subscribe
}
enum FeedErrorType {
    case defaultErr, refreshErr
}
enum MoveDirection {
    case top, left, right, bottom
}
