//
//  ImagePickerViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 27/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
class ImagePickerViewModel: ObservableObject {
    @Published
    var pickedImage: UIImage?
    @Published
    var showPicker = false
    @Published
    var source: Picker.Source = .library
    @Published
    var alertState: CustomAlert.ActionState = .none
    @Published
    var errorType: Picker.CameraError?
    @Published
    var showDeleteConfirmation = false
    func getImageActions() -> [CustomAlertButton] {
        var items = [CustomAlertButton(text: "take_photo", type: .defaultBtn, action: {
            self.presentPickerSheet(.camera)
        }), CustomAlertButton(text: "open_gallery", type: .defaultBtn, action: {
            self.presentPickerSheet(.library)
        })]
        let accountService = AccountService()
        if let account = accountService.getStoredUser(), let _ = account.avatar {
            items.append(CustomAlertButton(text: "remove_photo", type: .cancelBtn, action: {
                self.showDeleteConfirmation = true
            }))
        }
        
        return items
    }
    
    func presentPickerSheet(_ which: Picker.Source) {
        do {
            if which == .camera {
                try Picker.checkCameraPermission()
            }
            source = which
            showPicker = true
        } catch {
            alertState = .form
            errorType = Picker.CameraError(error: error as! Picker.PickerError)
            return
        }
    }
    func getSourceType() -> UIImagePickerController.SourceType {
        if source == .camera {
            return .camera
        }
        return .photoLibrary
    }
}
