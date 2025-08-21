//
//  ImagePickerSheetView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 27/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI

struct ImagePickerSheetView: View {
    @EnvironmentObject
    var stateVM: StateViewModel
    @StateObject
    private var imagePickerVM = ImagePickerViewModel()
    var body: some View {
        GeometryReader { _ in }
            .sheet(isPresented: $imagePickerVM.showPicker) {
                ImagePicker()
                    .ignoresSafeArea()
            }
            .onAppear(perform: presentPickerSheet)
            .onChange(of: imagePickerVM.alertState, perform: { state in
                if state != .none {
                    presentPickerAlert()
                } else {
                    dismissPickerAlert()
                }
            })
            .onChange(of: imagePickerVM.pickedImage) { resultImage in
                if let pickedImage = resultImage {
                    stateVM.imagePickerSheet?.onResult(pickedImage)
                }
            }
            .onChange(of: imagePickerVM.showDeleteConfirmation) { show in
                if show {
                    stateVM.sheetItemAction = .delete
                }
            }
            .environmentObject(imagePickerVM)
    }
    private func presentPickerSheet() {
        self.stateVM.presentSheet(contentItem: SheetAlertContent(title: nil, message: nil, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: stateVM.dismissPicker), actionBtn: nil, sheetItems: imagePickerVM.getImageActions()))
    }
    private func presentPickerAlert() {
        stateVM.dismissPicker()
        withAnimation(.easeInOut) {
            self.stateVM.presentAlert(contentItem: getPickerAlertContent())
        }
    }
    private func dismissPickerAlert() {
        self.imagePickerVM.alertState = .none
    }
    private func getPickerAlertContent() -> SheetAlertContent {
        if let errorType = imagePickerVM.errorType {
            if errorType.error == .restricted || errorType.error == .denied {
                return SheetAlertContent(title: AlertText(text: "allow_access"), message: AlertText(text: LocalizedStringKey(errorType.message), textFont: .body, textWeight: .regular), dismissBtn: CustomAlertButton(text: "not_now", textWeight: .semibold, type: .defaultBtn, action: dismissPickerAlert), actionBtn: CustomAlertButton(text: "settings", type: .defaultBtn, action: stateVM.openAppSettings))
            }
            return SheetAlertContent(title: nil, message: AlertText(text: LocalizedStringKey(errorType.message), textFont: .body, textWeight: .regular), dismissBtn: CustomAlertButton(text: "close", type: .cancelBtn, action: dismissPickerAlert), actionBtn: nil)
        }
        return SheetAlertContent(dismissBtn: CustomAlertButton(text: "", type: .cancelBtn, action: nil))
    }
}
struct ImagePickerPresent {
    let onResult: (UIImage) -> Void
}
struct ImagePickerSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ImagePickerSheetView()
    }
}
