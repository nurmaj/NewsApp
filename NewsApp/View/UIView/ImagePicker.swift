//
//  ImagePicker.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 27/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//
import SwiftUI
import Photos

struct ImagePicker: UIViewControllerRepresentable {
    //@StateObject
    @EnvironmentObject
    var viewModel: ImagePickerViewModel
    @Environment(\.presentationMode)
    private var presentationMode
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.delegate = context.coordinator
        
        pickerController.allowsEditing = true
        pickerController.sourceType = viewModel.getSourceType()
        
        return pickerController
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    final class Coordinator: NSObject {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
    }
}
extension ImagePicker.Coordinator: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    override class func provideImageData(_ data: UnsafeMutableRawPointer, bytesPerRow rowbytes: Int, origin x: Int, _ y: Int, size width: Int, _ height: Int, userInfo info: Any?) {
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            parent.viewModel.pickedImage = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            parent.viewModel.pickedImage = originalImage
        }
 
        parent.presentationMode.wrappedValue.dismiss()
    }
}
