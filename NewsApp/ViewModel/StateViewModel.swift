//
//  StateViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 7/6/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

//MARK: All States on root view
class StateViewModel: ObservableObject {
    var alertContent: SheetAlertContent?
    var sheetContent: SheetAlertContent?
    @Published
    var imagePickerSheet: ImagePickerPresent?
    @Published
    var sheetItemAction: API.ActionType?
    /**/
    @Published
    var sheetState = CustomAlert.ActionState.none
    @Published
    var alertState = CustomAlert.ActionState.none
    @Published
    var resultMsg: String?
    @Published
    var resultMsgIc: String?
    @Published
    var editTextVal: String = ""
    /**/
    @Published
    var webViewItem: WebViewItem?
        
    private var cancelBag = DisposeBag()
    
    func presentAlert(contentItem: SheetAlertContent) {
        self.alertContent = contentItem
        self.alertState = .form
    }
    func presentSheet(contentItem: SheetAlertContent) {
        self.sheetContent = contentItem
        self.sheetState = .form
    }
    func presentPicker(onResult: @escaping (UIImage) -> ()) {
        self.imagePickerSheet = ImagePickerPresent(onResult: onResult)
    }
    
    func alertPresented() -> Bool {
        return alertState != .none
    }
    func sheetPresented() -> Bool {
        return sheetState != .none
    }
    
    func alertColorScheme() -> ColorScheme? {
        return alertContent?.forPage == .video ? .dark : nil
    }
    
    func getEditTextValue() -> String {
        return editTextVal
    }
    
    func setAlertState(_ newState: CustomAlert.ActionState) {
        self.alertState = newState
    }
    func setSheetState(_ newState: CustomAlert.ActionState) {
        self.sheetState = newState
    }
    
    func setResultMsg(_ msg: String?, icon: String? = nil) {
        self.resultMsg = msg
        self.resultMsgIc = icon
    }
    
    func dismissAlert() {
        self.alertState = .none
        self.alertContent = nil
        self.editTextVal = ""
    }
    func dismissSheet() {
        self.sheetState = .none
        self.sheetContent = nil
    }
    func dismissPicker() {
        if sheetPresented() {
            dismissSheet()
        }
        self.imagePickerSheet = nil
    }
    func dismissSheetAction() {
        self.sheetItemAction = nil
    }
    /* Custom functions */
    func sendReport(page: String, issueItem: String?) {
        let text = getEditTextValue()
        if text.isEmpty {
            setResultMsg(nil)
            setAlertState(.failed)
            return
        }
        setAlertState(.sending)
        let networkRequest = APIRequest()
        networkRequest.sendReportIssue(from: page, text: text, issueItem: issueItem)
            .sink(receiveCompletion: { completion in
                switch(completion) {
                case .failure(.parseError):
                    self.setAlertState(.failed)
                    self.setResultMsg("default_err_msg")
                default: break
                }
            }) { response in
                var defaultMsg = "default_err_msg"
                if response.success {
                    defaultMsg = "default_success_msg"
                    self.editTextVal = ""
                    self.setAlertState(.success)
                } else {
                    self.setAlertState(.failed)
                }
                self.setResultMsg(response.message ?? defaultMsg)
            }
            .store(in: cancelBag)
    }
    func openAppSettings() {
        dismissAlert()
        if let appURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appURL)
        }
    }
}
