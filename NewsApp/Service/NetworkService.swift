//
//  NetworkService.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol NetworkRequest {
    func loadData(_ url: URL) -> AnyPublisher<Data, Error>
    func request<T>(from request: APIService) -> AnyPublisher<T, APIError> where T: Decodable
    func request<T>(from request: APIService) async throws -> Result<T, APIError> where T: Decodable
    func sendData(from request: APIService) -> AnyPublisher<String?, APIError>
}

extension NetworkRequest {
    private func urlRequest(remote: APIService) -> URLRequest {
        var request = URLRequest(url: remote.url)
        request.httpMethod = remote.method
        if let headers = remote.headers() {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpBody = try? remote.body()
        return request
    }
    func request<T>(from request: APIService) -> AnyPublisher<T, APIError> where T: Decodable {
        return URLSession.shared.dataTaskPublisher(for: urlRequest(remote: request))
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                print("STATUS_CODE: \(httpResponse.statusCode)")
                //logger.log(response: httpResponse, data: data, error: nil)
                guard HTTPCodes.success.contains(httpResponse.statusCode) else {
                    throw APIError.httpCode(httpResponse.statusCode)
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> APIError in
                print("REMOTE MAP ERROR: \(error)")
                return APIError.parseError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    func request<T>(from request: APIService) async throws -> Result<T, APIError> where T: Decodable {
        let (data, response) = try await URLSession.shared.data(for: urlRequest(remote: request))
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(APIError.unknown)
        }
        guard HTTPCodes.success.contains(httpResponse.statusCode) else {
            throw APIError.httpCode(httpResponse.statusCode)
        }
        do {
            return .success(try JSONDecoder().decode(T.self, from: data))
        } catch {
            return .failure(APIError.parseError)
        }
    }
    func loadData(_ url: URL) -> AnyPublisher<Data, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                guard HTTPCodes.success.contains(httpResponse.statusCode) else {
                    throw APIError.httpCode(httpResponse.statusCode)
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    func sendData(from request: APIService) -> AnyPublisher<String?, APIError> {
        return URLSession.shared.dataTaskPublisher(for: urlRequest(remote: request))
            .tryMap { (data, response) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                guard HTTPCodes.success.contains(httpResponse.statusCode) else {
                    throw APIError.httpCode(httpResponse.statusCode)
                }
                return String(data: data, encoding: .utf8)
            }
            .mapError { error -> APIError in
                return APIError.unknown
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

enum NetworkingState {
    case inited, processing, finished, success, failed
}

protocol APIRequestType: NetworkRequest {
    func loadFeedItems(itemsKey: String, setLaunchData: Bool, downTimestamp: Int?, upTimestamp: Int?) -> AnyPublisher<[FeedItem], APIError>
    func loadFeedItem(detailIId: String, with type: FeedType, feedKey: String, from point: FromPoint) -> AnyPublisher<FeedItem, APIError>
    func loadNewsItemText(id: String, which textType: NewsItem.TextType) -> AnyPublisher<NewsItemText, APIError>
    func loadNewsItemsForPhrase(with phrase: String, type: PhraseType, downTimestamp: Int?) -> AnyPublisher<[NewsItem], APIError>
    func sendNewsView(detailIId: String, hash: String?, with type: FeedType, feedKey: String, extra params: [String: String]?) -> AnyPublisher<String?, APIError>
    func downloadRemoteFile(fileUrl: URL) -> AnyPublisher<Data, Error>
    func sendReportIssue(from page: String, text: String, issueItem: String?) -> AnyPublisher<PostResponse, APIError>
    //func loadAdItem(target: AdTarget, nextTarget: AdTarget?, pageKey: String, newsItemId: String) -> AnyPublisher<AdResponse, APIError>
    func loadAdItem(targets: [AdTarget], pageKey: String, newsItemId: String) -> AnyPublisher<AdResponse, APIError>
    func makeAuthRequest(authType: AccountRequestKey, email: String, name: String?, pwd: String?) -> AnyPublisher<AccountResponse, APIError>
    func logoutOnRemote(account: Account) -> AnyPublisher<PostResponse, APIError>
    func retrieveAccountDeleteUrl(for account: Account) -> AnyPublisher<AccountUrlResponse, APIError>
    func sendDeviceInfo(deviceId: Int, deviceToken: String?, configSetkey: String?, extra params: [String: String]?) -> AnyPublisher<DeviceResponse, APIError>
    func getWebSearchURL(phrase: String) -> URL
    func verifyPayment(for account: Account, refererUrl: URL?) -> AnyPublisher<PostResponse, APIError>
}
//extension APIRequest: NetworkRequest {
struct APIRequest: APIRequestType {
    func loadFeedItems(itemsKey: String, setLaunchData: Bool, downTimestamp: Int?, upTimestamp: Int?) -> AnyPublisher<[FeedItem], APIError> {
        return request(from: NewsItemRemote(itemsKey: itemsKey, setLaunchData: setLaunchData, downTimestamp: downTimestamp, upTimestamp: upTimestamp))
    }
    func loadFeedItem(detailIId: String, with type: FeedType, feedKey: String, from point: FromPoint) -> AnyPublisher<FeedItem, APIError> {
        return request(from: NewsItemRemote(itemsKey: feedKey, id: detailIId, with: type, from: point))
    }
    func loadNewsItemText(id: String, which textType: NewsItem.TextType) -> AnyPublisher<NewsItemText, APIError> {
        return request(from: NewsItemRemote(id: id, textType: textType))
    }
    func loadNewsItemsForPhrase(with phrase: String, type: PhraseType, downTimestamp: Int?) -> AnyPublisher<[NewsItem], APIError> {
        return request(from: NewsItemRemote(phrase: phrase, type: type, downTimestamp: downTimestamp))
    }
    func sendNewsView(detailIId: String, hash: String?, with type: FeedType, feedKey: String, extra params: [String: String]?) -> AnyPublisher<String?, APIError> {
        return sendData(from: NewsItemRemote(viewed: detailIId, hash: hash, with: type, itemsKey: feedKey, extra: params))
    }
    func sendPageShareNumber(url: String) -> AnyPublisher<String?, APIError> {
        return sendData(from: AnalyticsRemote(shareUrl: url))
    }
    func downloadRemoteFile(fileUrl: URL) -> AnyPublisher<Data, Error> {
        return loadData(fileUrl)
    }
    func sendReportIssue(from page: String, text: String, issueItem: String?) -> AnyPublisher<PostResponse, APIError> {
        return request(from: ReportIssueRemote(from: page, text: text, issueItem: issueItem))
    }
    func makeAuthRequest(authType: AccountRequestKey, email: String, name: String?, pwd: String?) -> AnyPublisher<AccountResponse, APIError> {
        return request(from: AccountRemote(authType: authType, email: email, name: name, cleanPwd: pwd))
    }
    func uploadNewAvatar(imageData: Data, account: Account) -> AnyPublisher<AvatarResponse, APIError> {
        return request(from: AccountRemote(image: imageData, query: .uploadAvatar, account: account))
    }
    func removeAvatar(account: Account) -> AnyPublisher<PostResponse, APIError> {
        return request(from: AccountRemote(requestKey: .removeAvatar, account))
    }
    func updateAccountInfo(newUsername: String, newFirstname: String, newLastname: String, account: Account) -> AnyPublisher<PostResponse, APIError> {
        return request(from: AccountRemote(key: .update, accountRequest: AccountUpdateRequest(id: account.id, email: account.email, token: account.token,
                                                                         newUsername: newUsername, newFirstname: newFirstname, newLastname: newLastname)))
    }
    func logoutOnRemote(account: Account) -> AnyPublisher<PostResponse, APIError> {
        return request(from: AccountRemote(requestKey: .logoutOnServer, account))
    }
    func retrieveAccountDeleteUrl(for account: Account) -> AnyPublisher<AccountUrlResponse, APIError> {
        return request(from: AccountRemote(requestKey: .deleteUrl, account))
    }
    func sendDeviceInfo(deviceId: Int, deviceToken: String?, configSetkey: String?, extra params: [String: String]?) -> AnyPublisher<DeviceResponse, APIError> {
        return request(from: AnalyticsRemote(deviceId, deviceToken, configSetkey, params))
    }
    /* Ad */
    func loadAdItem(targets: [AdTarget], pageKey: String, newsItemId: String) -> AnyPublisher<AdResponse, APIError> {
        return request(from: AdItemRemote(targets: targets, pageKey: pageKey, newsItemId: newsItemId))
    }
    func sendAdShowedData(adItem: AdItem, page: String) -> AnyPublisher<String?, APIError> {
        return sendData(from: AdItemRemote(adItem: adItem, queryName: "show_ad", queryVal: "1", page: page, extra: nil))
    }
    func sendAdClosedData(adItem: AdItem, closePlace: AdClosePlace, page: String) -> AnyPublisher<String?, APIError> {
        return sendData(from: AdItemRemote(adItem: adItem, queryName: "skip_ad", queryVal: "1", page: page, extra: [URLQueryItem(name: "skip_from", value: "\(closePlace.rawValue)")]))
    }
    /**/
    func setPollVote(pollID: String, selectedOption: PollOptionItem, extra params: [String: String]?) -> AnyPublisher<PollResponse, APIError> {
        return request(from: PollRemote(pollID: pollID, selected: selectedOption, extraParams: params))
    }
    func getWebSearchURL(phrase: String) -> URL {
        return SearchRemote(phrase: phrase).url
    }
    /**/
    func verifyPayment(for account: Account, refererUrl: URL?) -> AnyPublisher<PostResponse, APIError> {
        return request(from: SubscriptionRemote(account: account, refererUrl: refererUrl, requestKey: .verifyPayment))
    }
}

// MARK: Async/Await implementation
extension APIRequest {
    func loadFeedItems(itemsKey: String, setLaunchData: Bool, downTimestamp: Int?, upTimestamp: Int?) async throws -> [FeedItem]? {
        let apiResult: Result<[FeedItem], APIError> = try await request(from:
                                                                        NewsItemRemote(itemsKey: itemsKey, setLaunchData: setLaunchData, downTimestamp: downTimestamp, upTimestamp: upTimestamp))
        
        switch apiResult {
        case .success(let feedItems):
            return feedItems
        case .failure(let error):
            throw error
        }
    }
    func loadFeedItem(detailIId: String, with type: FeedType, feedKey: String, from point: FromPoint) async throws -> FeedItem? {
        let apiResult: Result<FeedItem, APIError> = try await request(from: NewsItemRemote(itemsKey: feedKey, id: detailIId, with: type, from: point))
        
        switch apiResult {
        case .success(let feedItem):
            return feedItem
        case .failure(let error):
            throw error
        }
    }
}

struct Logger {
    func log(request: URLRequest) {
       print("\n - - - - - - - - - - OUTGOING - - - - - - - - - - \n")
       defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
       let urlAsString = request.url?.absoluteString ?? ""
       let urlComponents = URLComponents(string: urlAsString)
       let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
       let path = "\(urlComponents?.path ?? "")"
       let query = "\(urlComponents?.query ?? "")"
       let host = "\(urlComponents?.host ?? "")"
       var output = """
       \(urlAsString) \n\n
       \(method) \(path)?\(query) HTTP/1.1 \n
       HOST: \(host)\n
       """
       for (key,value) in request.allHTTPHeaderFields ?? [:] {
          output += "\(key): \(value) \n"
       }
       if let body = request.httpBody {
          output += "\n \(String(data: body, encoding: .utf8) ?? "")"
       }
       print(output)
    }
    func log(response: HTTPURLResponse?, data: Data?, error: Error?) {
       print("\n - - - - - - - - - - INCOMMING - - - - - - - - - - \n")
       defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
       let urlString = response?.url?.absoluteString
       let components = NSURLComponents(string: urlString ?? "")
       let path = "\(components?.path ?? "")"
       let query = "\(components?.query ?? "")"
       var output = ""
       if let urlString = urlString {
          output += "\(urlString)"
          output += "\n\n"
       }
       if let statusCode =  response?.statusCode {
          output += "HTTP \(statusCode) \(path)?\(query)\n"
       }
       if let host = components?.host {
          output += "Host: \(host)\n"
       }
       for (key, value) in response?.allHeaderFields ?? [:] {
          output += "\(key): \(value)\n"
       }
       if let body = data {
          output += "\n\(String(data: body, encoding: .utf8) ?? "")\n"
       }
       if error != nil {
          output += "\nError: \(error!.localizedDescription)\n"
       }
       print(output)
    }
}
