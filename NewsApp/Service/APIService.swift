//
//  Api.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 15/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

protocol APIService {
    var baseUrl: String { get }
    var path: String { get }
    var urlQueries: [URLQueryItem] { get }
    var method: HTTPMethod { get }
    func headers() -> [String: String]?
    var bodyComponents: URLComponents? { get }
    func body() throws -> Data?
}
extension APIService {
    var baseUrl: String {
        return API.Endpoint.baseUrl
    }
    var path: String { "/" }
    fileprivate var baseUrlQueries: [URLQueryItem] {
        return [
            URLQueryItem(name: "app_id", value: API.appIdForRemote),
            URLQueryItem(name: "v", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
        ]
    }
    var url: URL {
        var components = URLComponents(string: self.baseUrl)
        components?.path += path
        components?.queryItems = baseUrlQueries + urlQueries
        return components!.url!
    }
    
    func headers() -> [String : String]? { nil }
    
    var bodyComponents: URLComponents? { return nil }
    
    func body() throws -> Data? {
        guard let compQuery = bodyComponents?.query else {
            return nil
        }
        return Data(compQuery.utf8)
    }
}
protocol APIAuthData {
    var authQueries: [URLQueryItem]? { get }
}
extension APIAuthData {
    var authQueries: [URLQueryItem]? {
        if let account = AccountService().getStoredUser() {
            return [URLQueryItem(name: "ln", value: account.name),
                    URLQueryItem(name: "el", value: account.email),
                    URLQueryItem(name: "te", value: account.token),
                    URLQueryItem(name: "md", value: "1005")]
        }
        return nil
    }
}
enum APIError: Error {
    case httpCode(HTTPCode)
    case invalidURL
    case parseError
    case unknown
}
enum RemoteError: Error {
    case internalError
    case serverError(_ statusCode: Int)
}
enum AccountRequestKey: String {
    case login="signin-account", restore="restore-account", signUp="signup-account", update="update-account", logoutOnServer="logout-account"
    case uploadAvatar="upload-avatar", removeAvatar="remove-avatar"
    case deleteUrl="delete-account-url"
}
enum APIRequestKey: String {
    case verifyPayment="aki_verify_payment"
}
extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .httpCode(code):
            return "Bad HTTP code: \(code)"
        case .invalidURL:
            return "Invalid URL"
        case .parseError:
            return "JSON response parsing error"
        case .unknown:
            return "Unknown response. Check your request"
        }
    }
}
typealias HTTPMethod = String
typealias HTTPCode = Int
typealias HTTPCodes = Range<HTTPCode>

extension HTTPCodes {
    static let success = 200 ..< 300
}

struct NewsItemRemote: APIService, APIAuthData {
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod
    var bodyComponents: URLComponents?
}
extension NewsItemRemote {
    // MARK: Retrieve news items for specific feed page
    init(itemsKey: String, setLaunchData: Bool, downTimestamp: Int?, upTimestamp: Int?) {
        self.urlQueries = [
            URLQueryItem(name: itemsKey, value: nil)
        ]
        if downTimestamp != nil {
            self.urlQueries.append(URLQueryItem(name: "next", value: "\(downTimestamp!)"))
        } else if upTimestamp != nil {
            self.urlQueries.append(URLQueryItem(name: "prev", value: "\(upTimestamp!)"))
        }
        self.method = "GET"
        if setLaunchData {
            self.bodyComponents = URLComponents()
            self.bodyComponents?.queryItems = [
                URLQueryItem(name: "accept_special", value: "1"),
                URLQueryItem(name: "target", value: "\(AdTarget.topAllPage.rawValue)"),
                URLQueryItem(name: "ad_ids", value: "\(Preference.string(.strKeyname, strKey: "ad_ids:\(AdTarget.topAllPage.rawValue)") ?? AdDefaults.IDs)"),
                URLQueryItem(name: "showed_ad_time", value: "\(Preference.string(.strKeyname, strKey: "ad_time:\(AdTarget.topAllPage.rawValue)") ?? AdDefaults.TIME)")
            ]
            self.method = "POST"
            
            if let authQueries = self.authQueries {
                self.bodyComponents?.queryItems?.append(contentsOf: authQueries)
            }
        } else if let authQueries = self.authQueries {
            self.bodyComponents = URLComponents()
            self.bodyComponents?.queryItems = authQueries
            self.method = "POST"
        }
    }
}
extension NewsItemRemote {
    // MARK: Retrieve specific news item
    init(itemsKey: String, id: String, with type: FeedType, from point: FromPoint) {
        self.urlQueries = [URLQueryItem(name: "aki_news_item", value: nil)]
        self.method = "POST"
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = [
            URLQueryItem(name: "aki_p_n_id", value: id),
            URLQueryItem(name: "news_md", value: "1004"),
            URLQueryItem(name: "load_point", value: point.rawValue),
            URLQueryItem(name: "source", value: itemsKey)
        ]
        if type == .poll {
            bodyComponents?.queryItems?.append(contentsOf: [
                URLQueryItem(name: "is_special", value: "1"),
                URLQueryItem(name: "special_type", value: type.rawValue)
            ])
        }
        if let authQueries = self.authQueries {
            self.bodyComponents?.queryItems?.append(contentsOf: authQueries)
        }
    }
}
extension NewsItemRemote {
    // MARK: Retrieve specific news item's text html
    init(id: String, textType: NewsItem.TextType) {
        self.urlQueries = [
            URLQueryItem(name: "aki_news_item_text", value: nil),
            URLQueryItem(name: "pnid", value: id)
        ]
        self.method = "GET"
        if let authQueries = self.authQueries {
            self.method = "POST"
            self.bodyComponents = URLComponents()
            self.bodyComponents?.queryItems?.append(contentsOf: authQueries)
        }
    }
}
extension NewsItemRemote {
    // MARK: Search and news by tag feature
    init(phrase: String, type: PhraseType, downTimestamp: Int?) {
        let phraseKeyName: String
        switch type {
        case .search:
            phraseKeyName = "appsearch"
        case .tag:
            phraseKeyName = "tag"
        }
        self.urlQueries = [
            URLQueryItem(name: phraseKeyName, value: phrase),
            URLQueryItem(name: "source", value: type.rawValue)
        ]
        if downTimestamp != nil {
            self.urlQueries.append(URLQueryItem(name: "next", value: "\(downTimestamp!)"))
        }
        self.method = "GET"
        if let authQueries = self.authQueries {
            self.method = "POST"
            self.bodyComponents = URLComponents()
            self.bodyComponents?.queryItems?.append(contentsOf: authQueries)
        }
    }
}
extension NewsItemRemote {
    // MARK: Send News read to remote counter
    init(viewed id: String, hash: String?, with type: FeedType, itemsKey: String, extra configs: [String: String]?) {
        self.urlQueries = [
            URLQueryItem(name: "up", value: id),
            URLQueryItem(name: "k", value: (hash ?? ""))
        ]
        self.method = "POST"
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = [
            URLQueryItem(name: "from", value: itemsKey),
        ]
        if type == .poll {
            bodyComponents?.queryItems?.append(contentsOf: [
                URLQueryItem(name: "is_special", value: "1"),
                URLQueryItem(name: "special_type", value: type.rawValue)
            ])
        }
        if let params = configs {
            for (key, value) in params {
                bodyComponents?.queryItems?.append(URLQueryItem(name: key, value: value))
            }
        }
        if let authQueries = self.authQueries {
            self.bodyComponents?.queryItems?.append(contentsOf: authQueries)
        }
    }
}
struct ReportIssueRemote: APIService, APIAuthData {
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod
    var bodyComponents: URLComponents?
}
extension ReportIssueRemote {
    init(from page: String, text: String, issueItem: String?) {
        self.urlQueries = [URLQueryItem(name: "aki_report_issue", value: nil)]
        self.method = "POST"
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = [
            URLQueryItem(name: "page", value: page),
            URLQueryItem(name: "item", value: issueItem),
            URLQueryItem(name: "text", value: text),
        ]
        if let authQueries = self.authQueries {
            self.bodyComponents?.queryItems?.append(contentsOf: authQueries)
        }
    }
}
struct AccountRemote: APIService {
    var baseUrl: String {
        return API.Endpoint.projectUrl
    }
    var path: String {
        return "/account/"
    }
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod
    
    private var headerList: [String : String]
    func headers() -> [String: String]? { return headerList }
    
    private var bodyData: Data?
    func body() throws -> Data? {
        return bodyData
    }
}
extension AccountRemote {
    init(authType: AccountRequestKey, email: String, name: String?, cleanPwd: String?) {
        self.method = "POST"
        self.headerList = [:]
        var components = URLComponents()
        self.urlQueries = [URLQueryItem(name: authType.rawValue, value: nil)]
        components.queryItems = [
            URLQueryItem(name: "account_email", value: "\(email)"),
        ]
        if let login = name {
            components.queryItems?.append(contentsOf: [URLQueryItem(name: "account_username", value: login)])
        }
        if let pwd = cleanPwd {
            let base64Pwd = pwd.base64Decoded
            components.queryItems?.append(contentsOf: [URLQueryItem(name: "account_pwd", value: base64Pwd)])
        }
        
        if let compQuery = components.query {
            self.bodyData = Data(compQuery.utf8)
        }
    }
}
extension AccountRemote {
    init(image: Data, query: AccountRequestKey, account: Account) {
        self.method = "POST"
        self.urlQueries = [URLQueryItem(name: query.rawValue, value: "1")]
        self.headerList = [:]
        let boundary = API.Endpoint.generateBoundary()
        
        var formData = Data("--\(boundary)\r\n".utf8)
        // Append Account Info
        var accountData = Data("Content-Disposition: form-data; name=account_token\r\n\r\n\(account.token)".utf8)
        accountData.append(Data("\r\n--\(boundary)\r\n".utf8))
        accountData.append(Data("Content-Disposition: form-data; name=account_id\r\n\r\n\(account.id)".utf8))
        accountData.append(Data("\r\n--\(boundary)\r\n".utf8))
        accountData.append(Data("Content-Disposition: form-data; name=account_email\r\n\r\n\(account.email)".utf8))
        formData.append(accountData)
        formData.append(Data("\r\n--\(boundary)\r\n".utf8))
        // Append File
        var fileData = Data("Content-Disposition: form-data; name=new_avatar; filename=\(getDateFileName())\r\nContent-Type: image/jpeg\r\n\r\n".utf8)
        fileData.append(image)
        formData.append(fileData)
        formData.append(Data("\r\n--\(boundary)--".utf8))
        self.headerList = ["Content-Type": "multipart/form-data; boundary=\(boundary)",
                        "Content-Length": "\(formData.count)"]
        self.bodyData = formData
    }
    private func getDateFileName() -> String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss"
        return df.string(from: date)
    }
}
extension AccountRemote {
    init(key: AccountRequestKey, accountRequest: AccountUpdateRequest) {
        self.method = "POST"
        self.urlQueries = [URLQueryItem(name: key.rawValue, value: "1")]
        self.headerList = ["Content-Type": "application/json"]
        let encoder = JSONEncoder()
        //encoder.dataEncodingStrategy
        self.bodyData = try? encoder.encode(accountRequest)
    }
}
extension AccountRemote {
    init(requestKey: AccountRequestKey, _ account: Account) {//APIRequestKey
        self.method = "POST"
        self.urlQueries = [URLQueryItem(name: requestKey.rawValue, value: "1")]
        self.headerList = [:]
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "account_token", value: "\(account.token)"),
            URLQueryItem(name: "account_id", value: "\(account.id)"),
            URLQueryItem(name: "account_email", value: "\(account.email)"),
        ]
        if requestKey == .removeAvatar {
            let extraQueries: [URLQueryItem] = [URLQueryItem(name: "image_hash", value: account.avatar?.id)]
            components.queryItems?.append(contentsOf: extraQueries)
        }
        if let compQuery = components.query {
            self.bodyData = Data(compQuery.utf8)
        }
    }
}
struct SubscriptionRemote: APIService {
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod
    var bodyComponents: URLComponents?
}
extension SubscriptionRemote {
    init(account: Account, refererUrl: URL?, requestKey: APIRequestKey) {
        self.urlQueries = [URLQueryItem(name: requestKey.rawValue, value: nil)]
        self.method = "POST"
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = [
            URLQueryItem(name: "user_id", value: "\(account.id)"),
            URLQueryItem(name: "user_token", value: account.token),
            URLQueryItem(name: "user_email", value: account.email),
            URLQueryItem(name: "referer_url", value: refererUrl?.absoluteString),
        ]
    }
}
struct AnalyticsRemote: APIService {
    var baseUrl: String {
        return API.Endpoint.analyticUrl
    }
    private var analyticsPath: String
    var path: String { analyticsPath }
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod = "POST"
    var bodyComponents: URLComponents?
}
extension AnalyticsRemote {
    init(_ deviceId: Int, _ deviceToken: String?, _ configSetkey: String?, _ extraParams: [String: String]?) {
        self.analyticsPath = "/app/"
        self.urlQueries = [URLQueryItem]()
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = []
        if deviceId == 0 || deviceToken?.count != DefaultAppConfig.tokenLength {
            if let deviceInfo = extraParams {
                for (key, value) in deviceInfo {
                    bodyComponents?.queryItems?.append(URLQueryItem(name: key, value: value))
                }
            }
        } else {
            bodyComponents?.queryItems = [
                URLQueryItem(name: "ate", value: deviceToken),
                URLQueryItem(name: "ned", value: "\(deviceId)"),
            ]
        }
        bodyComponents?.queryItems?.append(URLQueryItem(name: "check_config", value: configSetkey))
        let accountService = AccountService()
        if let user = accountService.getStoredUser() {
            bodyComponents?.queryItems?.append(URLQueryItem(name: "ud", value: "\(user.id)"))
            bodyComponents?.queryItems?.append(URLQueryItem(name: "te", value: user.token))
            bodyComponents?.queryItems?.append(URLQueryItem(name: "md", value: "1005"))
        }
    }
}
extension AnalyticsRemote {
    init(shareUrl: String) {
        self.analyticsPath = "/counter/"
        self.urlQueries = [
            URLQueryItem(name: "share-counter", value: nil),
        ]
        self.bodyComponents = URLComponents()
        self.bodyComponents?.queryItems = [
            URLQueryItem(name: "share_url", value: shareUrl),
            URLQueryItem(name: "from_url", value: shareUrl)
        ]
    }
}
struct AdItemRemote: APIService {
    var baseUrl: String {
        return API.Endpoint.adUrl
    }
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod
    var bodyComponents: URLComponents?
}
extension AdItemRemote {
    init(targets: [AdTarget], pageKey: String, newsItemId: String) {
        self.urlQueries = [URLQueryItem]()
        self.method = "POST"
        let encoder = JSONEncoder()
        var params = [String: AdTargetParams]()
        for target in targets {
            params["\(target.rawValue)"] = AdTargetParams(ids: Preference.string(.strKeyname, strKey: "ad_ids:\(target.rawValue)") ?? AdDefaults.IDs
                                                          , time: Preference.string(.strKeyname, strKey: "ad_time:\(target.rawValue)") ?? AdDefaults.TIME)
        }
        
        let targetParams: Data = (try? encoder.encode(params)) ?? Data(AdDefaults.EMPTY_JSON.utf8)
        self.bodyComponents = URLComponents()
        let targetsJson: Data = (try? encoder.encode(targets)) ?? Data(AdDefaults.EMPTY_JSON_ARR.utf8)
        bodyComponents?.queryItems = [
            URLQueryItem(name: "targets", value: String(data: targetsJson, encoding: .utf8)),
            URLQueryItem(name: "target_params", value: String(data: targetParams, encoding: .utf8)),
            URLQueryItem(name: "from_page", value: "\(pageKey)"),
        ]
    }
}
extension AdItemRemote {
    init(adItem: AdItem, queryName: String, queryVal: String?, page: String, extra bodyQueries: [URLQueryItem]?) {
        self.urlQueries = [URLQueryItem(name: queryName, value: queryVal)]
        self.method = "POST"
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = [
            URLQueryItem(name: "ad_id", value: "\(adItem.id)"),
            URLQueryItem(name: "target", value: "\(adItem.target.rawValue)"),
            URLQueryItem(name: "banner_id", value: "\(adItem.bannerId)"),
            URLQueryItem(name: "size", value: "\(adItem.size.rawValue)"),
            URLQueryItem(name: "from_page", value: page),
            URLQueryItem(name: "md", value: "1005"),
        ]
        if let extraQueries = bodyQueries {
            bodyComponents?.queryItems?.append(contentsOf: extraQueries)
        }
    }
}
/**/
struct PollRemote: APIService {
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod = "POST"
    var bodyComponents: URLComponents?
}
extension PollRemote {
    init(pollID: String, selected option: PollOptionItem, extraParams: [String: String]?) {
        self.urlQueries = [URLQueryItem(name: "aki_vote", value: "1")]
        self.bodyComponents = URLComponents()
        bodyComponents?.queryItems = [
            URLQueryItem(name: "poll_id", value: "\(pollID)"),
            URLQueryItem(name: "voted_id", value: "\(option.id)"),
            URLQueryItem(name: "vote_md", value: "1009"),
        ]
        if let deviceInfo = extraParams {
            for (key, value) in deviceInfo {
                bodyComponents?.queryItems?.append(URLQueryItem(name: key, value: value))
            }
        }
    }
}
struct SearchRemote: APIService {
    var baseUrl: String {
        return API.Endpoint.projectUrl
    }
    var path: String {
        return "/search/"
    }
    var urlQueries: [URLQueryItem]
    var method: HTTPMethod
}
extension SearchRemote {
    init(phrase: String) {
        self.method = "POST"
        self.urlQueries = [URLQueryItem(name: "query", value: phrase)]
    }
}
