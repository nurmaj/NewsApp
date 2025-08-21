//
//  LoginViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 8/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

class LoginViewModel: ObservableObject {
    @Published
    var userName = ""
    @Published
    var userPwd = ""
    @Published
    var userPwdConfirm = ""
    @Published
    var userEmail = ""
    /**/
    @Published
    var signInState: NetworkingState = .inited
    @Published
    var keyboardOpened = false
    @Published
    var modalPresented = false
    @Published
    var authType: AccountRequestKey = .login
    @Published
    var successMsg = ""
    @Published
    var errorMsg = ""
    private var disposeBag = DisposeBag()
    func closeModal() {
        let fromAuthType = self.authType
        self.authType = .login
        self.modalPresented = false
        self.signInState = .inited
        cleanTypeFields(which: fromAuthType)
    }
    func openModal(which: AccountRequestKey) {
        self.authType = which
        self.modalPresented = true
    }
    func cleanTypeFields(which: AccountRequestKey) {
        userEmail = ""
        errorMsg = ""
        successMsg = ""
        if which == .signUp {
            userName = ""
            userPwd = ""
            userPwdConfirm = ""
        }
        disposeBag.cancel()
    }
    func makeAuthRequest(onSignIn: @escaping (Account) -> Void) {
        if authType == .signUp {
            if userPwd.count < 6 {
                self.errorMsg = "password_too_short"
                return
            } else if userPwd != userPwdConfirm {
                self.errorMsg = "password_not_match"
                return
            }
        }
        self.errorMsg = ""
        self.signInState = .processing
        let apiRequest = APIRequest()
        apiRequest.makeAuthRequest(authType: authType, email: userEmail, name: userName, pwd: userPwd)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(_):
                    self.signInState = .failed
                    self.errorMsg = "default_err_msg"
                default: break
                }
            }) { response in
                if response.success {
                    if let newUser = response.user {
                        let accountService = AccountService()
                        accountService.storeRemoteUser(newUser) { success in
                            if success {
                                self.successMsg = response.message ?? self.getAuthTypeDefaultMessage(type: self.authType, isSuccess: true)
                                self.signInState = .success
                                onSignIn(newUser)
                            } else {
                                self.errorMsg = "failed_store_account_on_device"
                                self.signInState = .failed
                            }
                        }
                    } else {
                        self.signInState = self.authType != .login ? .success : .failed
                    }
                } else {
                    self.errorMsg = response.message ?? self.getAuthTypeDefaultMessage(type: self.authType)
                    self.signInState = .failed
                }
            }
            .store(in: disposeBag)
    }
    private func getAuthTypeDefaultMessage(type: AccountRequestKey, isSuccess: Bool = false) -> String {
        let msgPrefix: String
        switch(type) {
        case .signUp:
            msgPrefix = "signup"
        case .restore:
            msgPrefix = "restore"
        default:
            msgPrefix = "signin"
        }
        return "\(msgPrefix)_\(isSuccess ? "success_msg" : "err_msg")"
    }
    func fieldsEmpty() -> Bool {
        if authType == .login && (userPwd.isEmpty || userName.isEmpty) {
            return true
        } else if authType == .signUp && (userPwd.isEmpty || userPwdConfirm.isEmpty) {
            return true
        }
        return authType != .login && userEmail.isEmpty
    }
}
