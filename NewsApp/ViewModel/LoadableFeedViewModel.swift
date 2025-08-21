//
//  RefreshableViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 16/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
protocol LoadableFeedViewModel {
    var showErrorMsg: Bool { get }
    var errorMsg: String { get }
    var errorMsgIcon: String { get }
    //func retrieveNewsItems(feedKey: String, point: FromPoint)
    func retrieveNewsItemsCombine(feedKey: String, point: FromPoint)
    func retrieveNewsItemsAsyncAwait(feedKey: String, point: FromPoint) async
    func showRetrieveError(which: FeedErrorType)
    //func fetchOnReload(onEnd: @escaping ()->())
}
typealias LoadableFeedVM = ObservableObject & LoadableFeedViewModel
