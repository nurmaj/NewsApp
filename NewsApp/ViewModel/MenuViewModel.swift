//
//  MenuViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

//import Foundation
import SwiftUI

class MenuViewModel: ObservableObject {
    @Published
    var user: Account?
    /*@Published
    var userAcc = Account(id: 1, email: "forjobb1@gmail.com", token: "asd", subscribed: false, name: "forjobb", firstName: nil, lastName: nil, avatar: ImageItem(id: "1", title: nil, author: nil, name: nil, thumb: URL(string: "https://static.newsapp.media/av/1/pbe3cc.100.jpg")!, sd: nil, hd: nil, sensitive: nil, width: nil, height: nil), balance: "0.00")*/
    @Published
    var menuItems = [MenuItem]()
    /*@Published
    var showWebViewModal = false*/
    @Published
    var webViewModalURL: URL?
    @Published
    var menuItemForDetail: MenuItem?
    @Published
    var alertState: CustomAlert.ActionState = .none
    @Published
    var showLoginView = false
    /* Message Banner View */
    @Published
    var resultMsg: String?
    @Published
    var resultMsgIcon = ""
    @Published
    var showMsgBanner = false
    /**/
    @Published
    var activeCoverItem: ActiveCover?
    @Published
    var accountEditMode = false
    @Published
    var avatarActionType: API.ActionType?
    @Published
    var avatarRequestState: NetworkingState = .inited
    @Published
    var accountUpdatingState: NetworkingState = .inited
    @Published
    var accountDeleteUrlState: NetworkingState = .inited
    @Published
    var accountDeleteUrl: URL?
    @Published
    var newAvatarImage: UIImage?
    @Published
    var saveAccountInfo = false
    @Published
    var alertType: CustomAlertType?
    @Published
    var logoutOnServerSuccess = false
    private var disposeBag = DisposeBag()
    init() {
        let sharedPage = API.SharedPage()
        self.menuItems = [MenuItem(name: "not", systemIcName: "bell.badge", customIcName: nil, detailKey: .notification),
            MenuItem(name: "support", systemIcName: "questionmark", customIcName: nil, detailKey: nil, urlStr: sharedPage.page(.helpCenter, section: .home)),
            MenuItem(name: "settings", systemIcName: "gearshape", customIcName: nil, detailKey: .settings),
            MenuItem(name: "report", systemIcName: "exclamationmark.bubble", customIcName: nil, detailKey: nil, action: {
                self.showAlert(which: .report)
            }),
            MenuItem(name: "privacy", systemIcName: "doc", customIcName: nil, detailKey: nil, urlStr: sharedPage.page(.policy, section: .none))]
    }
    func showAlert(which: CustomAlertType) {
        self.alertType = which
        self.alertState = .form
    }
    func checkAccountStatus() {
        if accountEditMode {
            accountEditMode = false
        }
        let accountService = AccountService()
        self.user = accountService.getStoredUser()
        //if let _ = self.user {
            /*self.menuItems.append(MenuItem(name: "logout", systemIcName: nil, customIcName: "logout", action: {
                self.alertState = .form
            }))*/
        //}
    }
    func logoutUser() {
        if let user = self.user {
            if logoutOnServerSuccess {
                self.logoutOnDevice(user)
                return
            }
            // MARK: First Logout on Remote
            let apiRequest = APIRequest()
            self.alertState = .sending
            apiRequest.logoutOnRemote(account: user)
                .sink(receiveCompletion: { completion in
                    switch(completion) {
                    case .failure(_):
                        self.alertState = .failed
                        self.showResultMsg(msg: "logout_error")
                    default: break
                    }
                }, receiveValue: { response in
                    self.alertState = .success
                    self.logoutOnServerSuccess = true
                    self.logoutOnDevice(user)
                })
                .store(in: disposeBag)
        }
    }
    private func logoutOnDevice(_ user: Account) {
        let accountService = AccountService()
        if accountService.logoutStoredUser(account: user.email) {
            self.alertState = .none
            self.showResultMsg(msg: "logout_success", ic: "trash")
            self.checkAccountStatus()
        } else {
            self.alertState = .failed
            self.showResultMsg(msg: "logout_error")
        }
    }
    func saveUserInfoToRemote(newUsername: String, newFirstname: String, newLastname: String) {
        if var user = self.user {
            let apiRequest = APIRequest()
            self.accountUpdatingState = .processing
            apiRequest.updateAccountInfo(newUsername: newUsername, newFirstname: newFirstname, newLastname: newLastname, account: user)
                .sink(receiveCompletion: { completion in
                    switch(completion) {
                    case .failure(_):
                        self.accountUpdatingState = NetworkingState.failed
                    default: break
                    }
                }, receiveValue: { response in
                    if response.success {
                        user.name = newUsername
                        user.firstName = !newFirstname.isEmpty ? newFirstname : nil
                        user.lastName = !newLastname.isEmpty ? newLastname : nil
                        let accountService = AccountService()
                        accountService.storeRemoteUser(user) { success in
                            if success {
                                self.accountUpdatingState = NetworkingState.success
                                self.checkAccountStatus()
                            } else {
                                self.accountUpdatingState = NetworkingState.failed
                            }
                        }
                    } else {
                        self.accountUpdatingState = NetworkingState.failed
                        if let message = response.message {
                            self.resultMsg = message
                        } else {
                            self.resultMsg = nil
                        }
                    }
                })
                .store(in: disposeBag)
        }
    }
    func saveImageToRemote(_ image: UIImage) {
        guard let user = self.user else {
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        self.newAvatarImage = image
        let apiRequest = APIRequest()
        self.avatarActionType = .add
        self.avatarRequestState = NetworkingState.processing
        apiRequest.uploadNewAvatar(imageData: imageData, account: user)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.avatarRequestState = NetworkingState.failed
                default: break
                }
            }, receiveValue: { response in
                if let newAvatar = response.avatar, response.success {
                    guard var user = self.user else {
                        self.avatarRequestState = NetworkingState.failed
                        return
                    }
                    user.avatar = newAvatar
                    let accountService = AccountService()
                    accountService.storeRemoteUser(user) { success in
                        if success {
                            self.avatarRequestState = NetworkingState.success
                            self.checkAccountStatus()
                        } else {
                            self.avatarRequestState = NetworkingState.failed
                        }
                    }
                } else {
                    self.avatarRequestState = NetworkingState.failed
                }
            })
            .store(in: disposeBag)
    }
    func cancelImageRemoteSave() {
        self.avatarActionType = nil
        self.avatarRequestState = .finished
        self.newAvatarImage = nil
        disposeBag.cancel()
    }
    func removeRemoteImage() {
        guard var user = self.user else {
            return
        }
        let apiRequest = APIRequest()
        self.avatarActionType = .delete
        self.avatarRequestState = NetworkingState.processing
        apiRequest.removeAvatar(account: user)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.avatarRequestState = NetworkingState.failed
                default: break
                }
            }, receiveValue: { response in
                if response.success {
                    user.avatar = nil
                    let accountService = AccountService()
                    accountService.storeRemoteUser(user) { success in
                        if success {
                            self.avatarRequestState = NetworkingState.success
                            self.checkAccountStatus()
                        } else {
                            self.avatarRequestState = NetworkingState.failed
                        }
                    }
                } else {
                    self.avatarRequestState = NetworkingState.failed
                }
            })
            .store(in: disposeBag)
    }
    func retrieveAccountDeleteUrl() {
        guard let user = self.user else {
            return
        }
        let apiRequest = APIRequest()
        self.accountDeleteUrlState = .processing
        apiRequest.retrieveAccountDeleteUrl(for: user)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.accountDeleteUrlState = .failed
                default: break
                }
            }, receiveValue: { response in
                if response.success {
                    self.accountDeleteUrlState = .success
                    self.accountDeleteUrl = response.url
                } else {
                    self.resultMsg = response.message
                    self.accountDeleteUrlState = .failed
                }
            })
            .store(in: disposeBag)
    }
    func showResultMsg(msg: String, ic: String = "exclamationmark.circle") {
        self.resultMsg = msg
        self.resultMsgIcon = ic
        self.showMsgBanner = true
    }
}
