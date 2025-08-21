//
//  AdItemViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 23/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Combine
class AdItemViewModel: ObservableObject {
    @Published
    var adItem: AdItem
    @Published
    var target: AdTarget
    @Published
    var bannerHeight = CGFloat.zero
    @Published
    var adFrameSize = CGSize.zero
    @Published
    var adAutoCloseTime: Int = .zero
    @Published
    var bannerData: Data?
    private let page: String
    private var closeAd: () -> ()
    private var timer: Cancellable?
    private var disposeBag = DisposeBag()
    init(adItem: AdItem, target: AdTarget, from page: String, closeAd: @escaping ()->()) {
        self.adItem = adItem
        self.target = target
        self.closeAd = closeAd
        self.page = page
    }
    deinit {
        self.timer?.cancel()
    }
    func getRemoteBannerData(remoteUrl: URL) {
        let request = APIRequest()
        request.downloadRemoteFile(fileUrl: remoteUrl)
            .sink(receiveCompletion: { _ in }) { resultData in
                self.bannerData = resultData
            }
            .store(in: disposeBag)
    }
    func setAdShowed() {
        if self.adItem.displayState == .showed || self.adItem.displayState == .closed {
            return
        }
        self.adItem.displayState = .showed
        if adItem.target == .fullscreenFeed || adItem.target == .fullscreenDetail {
            self.timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.adAutoCloseTime += 1
                }
        }
        self.sentAdShowInfo()
        Preference.set(adItem.showedTime, key: .strKeyname, strKey: "ad_time:\(adItem.target.rawValue)")
    }
    func closeAdView(closingWhere: AdClosePlace) {
        self.closeAd()
        if target != .topAllPage {
            self.sendAdCloseInfo(closed: closingWhere)
        }
    }
    func isFullscreenAd() -> Bool {
        return target == .fullscreenFeed || target == .fullscreenDetail
    }
    private func sentAdShowInfo() {
        let request = APIRequest()
        request.sendAdShowedData(adItem: adItem, page: page)
            .sink(receiveCompletion: { _ in }) { result in
                if result == "1" {
                    Preference.set(self.adItem.adIds, key: .strKeyname, strKey: "ad_ids:\(self.adItem.target.rawValue)")
                }
            }
            .store(in: disposeBag)
    }
    private func sendAdCloseInfo(closed from: AdClosePlace) {
        let request = APIRequest()
        request.sendAdClosedData(adItem: adItem, closePlace: from, page: page)
            .sink(receiveCompletion: { _ in }) { _ in }
            .store(in: disposeBag)
    }
}
