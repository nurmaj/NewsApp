//
//  PollViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 21/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

class PollViewModel: ObservableObject {
    @Published
    var pollItem: PollItem
    @Published
    var alertState: CustomAlert.ActionState = .none
    @Published
    var resultMsg: String = ""
    @Published
    var selectedOption: PollOptionItem?
    @Published
    var user: Account?
    var presentLoginView: (LoginViewItem) -> Void
    
    private var disposeBag = DisposeBag()
    init(_ pollItem: PollItem, _ presentLoginView: @escaping (LoginViewItem) -> Void) {//, onMsgBannerShow: @escaping (String) -> ()
        self.pollItem = pollItem
        self.presentLoginView = presentLoginView
        let accountService = AccountService()
        self.user = accountService.getStoredUser()
    }
    func hasExpired() -> Bool {
        if let endDateISO = pollItem.endDateISO {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let endDateOpt = dateFormatter.date(from: endDateISO)
            guard let endDate = endDateOpt else {
                return false
            }
            return endDate <= Date()
        }
        return false
    }
    func optionHasVote(option id: String) -> Bool {
        return id == selectedOption?.id
        || Preference.array(.votedPollPrefix, strKey: pollItem.id)?
                .first(where: { $0 == id }) == id
    }
    func hasVoted() -> Bool {
        if let votedItems = Preference.array(.votedPollPrefix, strKey: pollItem.id), !votedItems.isEmpty {
            return true
        }
        return false
    }
    func hideResultBeforeVote() -> Bool {
        if hasExpired() {
            return false
        } else if !pollItem.canVote {
            return false
        } else if let votedItems = Preference.array(.votedPollPrefix, strKey: pollItem.id), !votedItems.isEmpty {
            return false
        }
        return self.pollItem.hideResult ?? false
    }
    func sendPollVote() {
        guard let selectedOption = self.selectedOption else {
            return
        }
        self.alertState = .sending
        let networkRequest = APIRequest()
        networkRequest.setPollVote(pollID: pollItem.id, selectedOption: selectedOption, extra: getPollParams())
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.resultMsg = "poll_vote_error"
                    self.alertState = .failed
                default: break
                }
            }) { result in
                if result.success {
                    guard let pollItem = result.pollItem else {
                        self.setFailure(result.message ?? "poll_vote_error")
                        return
                    }
                    guard let votedId = pollItem.selectedVoteId else {
                        self.setFailure(result.message ?? "poll_vote_error")
                        return
                    }
                    self.setVotedOptionForPoll(optionId: votedId)
                    self.resultMsg = result.message ?? "poll_vote_success"
                    self.alertState = .success
                    // Save poll vote selection
                } else {
                    self.setFailure(result.message ?? "poll_vote_error")
                }
            }
            .store(in: disposeBag)
    }
    private func setVotedOptionForPoll(optionId: String) {
        var votedItemList = Preference.array(.votedPollPrefix, strKey: pollItem.id)
        if votedItemList.isEmptyOrNil {
            votedItemList = []
        }
        votedItemList?.append(optionId)
        Preference.set(votedItemList, key: .votedPollPrefix, strKey: pollItem.id)
    }
    private func setFailure(_ msg: String) {
        self.resultMsg = msg
        self.alertState = .failed
    }
    private func getPollParams() -> [String: String] {
        var params: [String: String] = ["ned": "\(Preference.int(.deviceInfoId))", "ate": Preference.string(.deviceInfoToken) ?? "",
                                        "free_space": (FileManager.default.systemFreeSize() ?? ""),
                                        "total_space": (FileManager.default.systemTotalSizeBytes() ?? "")]
        if let user = self.user {
            params["el"] = user.email
            params["ud"] = "\(user.id)"
            params["te"] = user.token
            params["md"] = "1005"
        }
        params.merge(API.Device.getInfo()) { (current, _) in current }
        return params
    }
}
