//
//  DownloadTaskModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 18/10/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Photos

class DownloadTaskModel: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published
    var isDownloading = false
    @Published
    var downloadTask: URLSessionDownloadTask?
    @Published
    var downloadProgress: Int = .zero
    @Published
    var showDownloadError = false
    @Published
    var downloadedUrl: URL?
    var alertState: CustomAlert.ActionState = .none
    private var alertType: AlertType = .photoAccess
    
    private var dirPath: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    private var fileName: String = ""
    private var destinationUrl: URL?
    private var fileType: FileType = .image
    private var completion: (() -> Void)?
    func saveRemoteVideo(_ outputURL: URL, fileType: FileType, _ completion: (() -> Void)?) {
        showDownloadError = false
        requestAuthorization {
            self.isDownloading = true
            self.fileType = fileType
            self.fileName = self.getFileName(outputURL, type: fileType)
            self.completion = completion
            guard let dirPath = self.dirPath else {
                return
            }
            self.destinationUrl = dirPath.appendingPathComponent(self.fileName)
            
            if let destinationUrl = self.destinationUrl, self.fileExists(path: destinationUrl.path) {
                self.createFileAsset()
            } else {
                self.downloadProgress = .zero
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                self.downloadTask = session.downloadTask(with: outputURL)
                self.downloadTask?.resume()
            }
        }
    }
    func cancelDownload() {
        isDownloading = false
        if let task = downloadTask, task.state == .running {
            task.cancel()
        }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destinationUrl = self.destinationUrl else {
            self.showDownloadError = true
            return
        }
        try? FileManager.default.removeItem(at: destinationUrl)
        do {
            // Move TMP file
            try FileManager.default.moveItem(at: location, to: destinationUrl)
            createFileAsset()
            /*DispatchQueue.main.async {
                // Them move
            }*/
        } catch {
            DispatchQueue.main.async {
                self.showDownloadError = true
            }
        }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > 0 && totalBytesExpectedToWrite > 0 {
            let progress = (CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)) * 100
            DispatchQueue.main.async {
                self.downloadProgress = Int(progress)
            }
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let _ = error {
            DispatchQueue.main.async {
                self.showDownloadError = true
            }
        }
    }
    private func createFileAsset() {
        PHPhotoLibrary.shared().performChanges({
            guard let destinationUrl = self.destinationUrl else {
                self.showDownloadError = true
                return
            }
            if self.fileType == .video {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationUrl)
            }
        }) { (result, error) in
            DispatchQueue.main.async {
                if let _ = error {
                    self.showDownloadError = true
                } else {
                    self.isDownloading = false
                    self.downloadedUrl = self.destinationUrl
                }
                //completion?(error)
                self.completion?()
            }
        }
    }
    private func getFileName(_ url: URL, type: FileType) -> String {
        return API.appNameLatin + "_" + type.rawValue + "_" + url.lastPathComponent
    }
    private func fileExists(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    private func requestAuthorization(completion: @escaping () -> Void) {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { (status) in
                DispatchQueue.main.async {
                    if status == .authorized {
                        completion()
                    } else if status == .denied {
                        self.cancelDownload()
                    }
                }
            }
        case .denied:
            cancelDownload()
            setAlert(type: .photoAccess)
        case .authorized:
            completion()
        default:
            return
        }
    }
    private func setAlert(type: AlertType) {
        self.alertType = type
        self.alertState = .form
    }
    enum FileType: String {
        case video, image
    }
    private enum AlertType: String {
        case photoAccess
    }
}
