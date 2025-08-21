//
//  Picker.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 27/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import UIKit
import AVFoundation
struct Picker {
    enum Source {
        case camera, library
    }
    enum PickerError: Error, LocalizedError {
        case unavailable, restricted, denied//, notRequested
        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "camera_unavailable"
            case .restricted, .denied:
                return "camera_access_description"
            /*case .notRequested:
                return "Camera access was not determined"*/
            }
        }
    }
    static func checkCameraPermission() throws {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            switch authStatus {
            /*case .notDetermined:
                throw PickerError.notRequested*/
            case .denied:
                throw PickerError.denied
            case .restricted:
                throw PickerError.restricted
            //case .authorized:
            default:
                break
            }
        } else {
            throw PickerError.unavailable
        }
    }
    struct CameraError {
        let error: Picker.PickerError
        var message: String {
            error.localizedDescription
        }
    }
}
