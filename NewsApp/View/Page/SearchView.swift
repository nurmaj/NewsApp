//
//  SearchView.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 6/7/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    @Binding
    var isPresented: Bool
    let onPresentDetail: (FeedItem) -> ()
    @StateObject
    var searchVM = SearchViewModel()
    
    var body: some View {
        VStack(spacing: .zero) {
            SearchFieldView(isPresented: $isPresented, searchVM: searchVM)
            if searchVM.loadingState == .inited || searchVM.loadingState == .processing && searchVM.newsItems.count == 0 {
                Color.black
                    .opacity(0.6)
                    .onTapGesture {
                        if searchVM.loadingState != .processing {
                            withAnimation(.easeInOut) {
                                self.isPresented = false
                            }
                        }
                    }
            } else if let errorMsg = searchVM.errorMsg {
                Text(LocalizedStringKey(errorMsg))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .font(.body)
                        .foregroundColor(Color("BlackTint"))
                        .padding(.vertical, 15)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color("WhiteBlackBg")))
                        .padding(.all, 8)
                Spacer()
            } else if searchVM.newsItems.count > .zero {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: .zero) {
                        ForEach(searchVM.newsItems) { newsItem in
                            Button(action: { presentDetail(newsItem) }) {
                                FeedItemRow(title: newsItem.title, date: newsItem.date, viewNum: newsItem.views, onlineNum: newsItem.onlineNum, image: newsItem.image?.outer, itemLayout: .small, showViewNum: false, showClosedLock: newsItem.closedStatus == .paid, isLaunchable: newsItem.redirectUrl != nil)
                            }
                        }
                    }
                }
            }
        }
        .background(Color("AccentLightColor").ignoresSafeArea())
        .overlay(searchVM.loadingState == .success || searchVM.loadingState == .failed ?
                 ShareFloatingView(url: searchVM.getWebUrlOfSearch(), shareId: searchVM.searchText, sharedCnt: nil, shareType: .searchPage, onShare: { _ in }) : nil
                 , alignment: .bottomTrailing)
        .onDisappear {
            searchVM.resetStates()
        }
    }
    private func presentDetail(_ newsItem: NewsItem) {
        self.onPresentDetail(FeedItem(newsItem: newsItem))
    }
}

struct SearchFieldView: View {
    @Binding
    var isPresented: Bool
    @StateObject
    var searchVM: SearchViewModel
    private var fieldHeight: CGFloat {
        32 + min((safeEdges?.top ?? 0), 4)
    }
    var body: some View {
        HStack(spacing: 8) {
            CleanTextField(viewModel: CleanTextFieldVM(focusable: true), textVal: $searchVM.searchText, hint: "search_in_project", fieldHeight: fieldHeight, leadingSpace: 20, onSubmit: onSearchAction, submitLabelType: .search)
                .frame(height: fieldHeight)
                .overlay(leadingFieldView, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color("GreyWhite"))
                )
            Button(action: onSearchCancelBtn) {
                Text("cancel")
                    .font(.callout)
                    .foregroundColor(.blue)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
            withAnimation {
                self.searchVM.keyboardOpened = true
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            withAnimation {
                self.searchVM.keyboardOpened = false
            }
        }
        .padding(.horizontal, (safeEdges?.left ?? 0) + 10)
        .padding(.bottom, min((safeEdges?.top ?? 0), 2) + 4)
        .frame(height: DefaultAppConfig.appNavBarHeight + (safeEdges?.top ?? 0), alignment: .bottom)
        .background(Color("WhiteBlackBg"))
    }
    var leadingFieldView: some View {
        ZStack {
            if searchVM.loadingState == .processing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            } else {
                Image(systemName: "magnifyingglass")
                    .padding(.leading, 4)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 24, height: 24)
    }
    private func onSearchAction() {
        withAnimation {
            UIApplication.shared.closeKeyboard()
        }
        searchVM.searchOnRemote(queryType: .search, bottom: false)
        FAnalyticsService.shared.sendLogEvent(id: searchVM.searchText, title: searchVM.searchText, type: "search")
    }
    private func onSearchCancelBtn() {
        withAnimation(.easeInOut) {
            self.isPresented = false
        }
    }
}
class SearchViewModel: ObservableObject {
    @Published
    var newsItems = [NewsItem]()
    @Published
    var loadingState = NetworkingState.inited
    /* State properties */
    @Published
    var searchText = ""
    @Published
    var keyboardOpened = false
    /**/
    @Published
    var errorMsg: String?
    @Published
    var bottomLoadCnt = Int.zero
    
    private var disposeBag = DisposeBag()
    
    func searchOnRemote(queryType: PhraseType, bottom: Bool) {
        self.errorMsg = nil
        if loadingState == .processing {
            if bottom {
                return
            }
            disposeBag.cancel()
        } else {
            self.loadingState = .processing
        }
        if !bottom {
            self.newsItems = []
        }
        let searchRequest = APIRequest()
        searchRequest.loadNewsItemsForPhrase(with: searchText, type: queryType, downTimestamp: getLastItemTimestamp(from: bottom))
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(.parseError):
                    self.loadingState = NetworkingState.failed
                    self.errorMsg = "default_err_msg"
                default: break
                }
            }, receiveValue: { newsItems in
                if bottom {
                    self.newsItems += newsItems
                    self.bottomLoadCnt += 1
                } else {
                    self.newsItems = newsItems
                    if newsItems.count == 0 {
                        self.errorMsg = "no_items_found_for_search_phrase"
                    }
                }
                self.loadingState = NetworkingState.success
            })
            .store(in: disposeBag)
    }
    private func getLastItemTimestamp(from bottom: Bool) -> Int? {
        if bottom {
            return newsItems.last?.timestamp
        }
        return nil
    }
    func getWebUrlOfSearch() -> URL {
        return APIRequest().getWebSearchURL(phrase: searchText)
    }
    func resetStates() {
        self.newsItems = []
        self.loadingState = .inited
        self.errorMsg = nil
        self.searchText = ""
    }
}
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(isPresented: .constant(true)) { _ in }
    }
}
