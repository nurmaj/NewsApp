//
//  PlayerViewModel.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 7/10/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import AVKit

class PlayerViewModel: ObservableObject {//AVPlayer
    @Published
    var player: AVPlayer?
    @Published
    var isPlaying: Bool = false
    @Published
    var isSeeking: Bool = false
    @Published
    var isBuffering: Bool = false
    @Published
    var paused: Bool = false
    @Published
    var pausedManually = false
    @Published
    var canPlay: Bool = false
    @Published
    var canDisplay: Bool = false
    @Published
    var posterImage: UIImage?
    // Control bar state
    @Published
    var barsMinimized = false
    @Published
    var preventBarsHide = false
    @Published
    var duration: Double = .zero
    //var duration: CMTime = .zero
    @Published
    var currentTime: Double = .zero
    @Published
    var progressWidth: CGFloat = AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH
    @Published
    var progressViewFullWidth: CGFloat = .zero
    @Published
    var closePlayer: Bool = false
    @Published
    var layerRect: CGSize = .zero
    @Published
    var videoRectSize: CGSize = .zero
    @Published
    var safeAreaSize: CGFloat = .zero
    /* Drag Offset */
    @Published
    var dismissDragOffsetY: CGFloat = .zero
    @Published
    var layerOpacity: Double = 1
    /**/
    @Published
    var showTopMenu = false
    /* URLs */
    @Published
    var videoFileUrl: URL?
    @Published
    var shareUrl: URL?
    @Published
    var parentId: String = ""
    /**/
    @Published
    var showPlayError = false
    @Published
    var playErrorMsg: String?
    
    /**/
    @Published
    var isFullscreen = false
    /* Report Issue */
    @Published
    var presentReportAlert = false
    let id: String
    var progressAnimationTime: Double {
        isSeeking || !isPlaying ? 0.2 : 0.8
    }
    @Published
    var barShowTime: Double = .zero
    
    var cancelBag = DisposeBag()
    private var timeObserverToken: Any?
    var observers = Set<NSKeyValueObservation>()
    init(videoPath: MediaPath, posterImage: UIImage?, shareUrl: URL?, videoRect: CGSize, parentId: String, id: String) {
        self.posterImage = posterImage
        self.shareUrl = shareUrl
        self.videoRectSize = videoRect
        self.parentId = parentId
        self.id = id
        
        self.videoFileUrl = getBetterQualityPath(videoPath)
        guard let videoUrl = self.videoFileUrl else {
            return
        }
        self.player = AVPlayer(url: videoUrl)
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.publisher(for: \.timeControlStatus).sink { [weak self] newStatus in
            if newStatus == .playing {
                self?.isPlaying = true
                if (self?.showPlayError ?? false) {
                    self?.showPlayError = false
                }
            } else if newStatus == .paused {
                self?.isPlaying = false
            }
        }
        .store(in: cancelBag)
        player?.currentItem?.publisher(for: \.isPlaybackBufferEmpty).sink {  [weak self] isBuffering in
            self?.isBuffering = isBuffering
            if !isBuffering && !(self?.isPlaying ?? false) && !(self?.playerPaused() ?? false) {
                self?.startPlay(notStartIfManual: false)
            }
        }
        .store(in: cancelBag)
        player?.currentItem?.publisher(for: \.isPlaybackBufferFull).sink {  [weak self] bufferFull in
            if bufferFull && !(self?.isPlaying ?? false) && !(self?.playerPaused() ?? false) {
                self?.startPlay(notStartIfManual: false)
            }
        }
        .store(in: cancelBag)
        player?.currentItem?.publisher(for: \.status).sink { [weak self] newStatus in
            if newStatus == .readyToPlay && self?.duration == .zero {
                self?.canPlay = true
                self?.duration = self?.player?.currentItem?.duration.seconds ?? .zero
            } else if newStatus == .failed {
                self?.showPlayError = true
                self?.playErrorMsg = self?.player?.currentItem?.error?.localizedDescription
                self?.pausePlayer()
            }
        }
        .store(in: cancelBag)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { _ in
                self.player?.seek(to: CMTime.zero)
                self.player?.play()
            }
            .store(in: cancelBag)
       
        setPeriodicTimeObserver()
    }
    private func setPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

        timeObserverToken = self.player?.addPeriodicTimeObserver(forInterval: time,
                                                          queue: .main) { [weak self] time in
            if (self?.canUpdateTime() ?? false) {
                let prevTime = self?.currentTime
                self?.currentTime = CMTimeGetSeconds(time)
                self?.calculateProgressWidth()
                self?.checkBarMinimizeState(prevTime ?? .zero)
            }
        }
    }
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    private func canUpdateTime() -> Bool {
        return !self.isSeeking && self.canPlay && self.isPlaying && !self.isBuffering
    }
    private func getBetterQualityPath(_ path: MediaPath) -> URL? {
        if let hd = path.hd, !Preference.bool(.dataSaver) {
            return hd
        } else if let sd = path.sd {
            return sd
        } else if let thumb = path.thumb {
            return thumb
        }
        return URL(string: API.Endpoint.projectUrl)
    }
    func playPause(manually: Bool) {
        if !paused {
            player?.pause()
            self.paused = true
            if manually {
                self.pausedManually = true
            }
        } else {
            startPlay(notStartIfManual: false)
        }
        resetBarShowTime()
    }
    func startPlay(notStartIfManual: Bool) {
        if notStartIfManual {
            return
        }
        player?.play()
        self.paused = false
        self.pausedManually = false
    }
    func playImmediately() {
        player?.playImmediately(atRate: 1.0)
        self.paused = false
        self.pausedManually = false
    }
    func pausePlayer() {
        player?.pause()
        self.paused = true
    }
    func playerPaused() -> Bool {
        return paused
    }
    func seekToWidth() {
        let secondsToSeek = getTimeFromProgressWidth()
        if let timescale = player?.currentTime().timescale {
            let time = CMTime(seconds: secondsToSeek, preferredTimescale: timescale)//CMTimeScale(NSEC_PER_SEC)
            currentTime = secondsToSeek
            player?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] finished in
                if finished {
                    self?.isSeeking = false
                }
            }
            resetBarShowTime()
            if !isPlaying {
                player?.play()
            }
        }
    }
    func getDuration() -> String {
        return formatSecondsToHMS(time: duration)
    }
    func getCurrentTime() -> String {
        return formatSecondsToHMS(time: isSeeking ? getTimeFromProgressWidth() : currentTime)
    }
    func isVertical() -> Bool {
        return videoRectSize.width > 0 && videoRectSize.height > 0 && videoRectSize.height > videoRectSize.width
    }
    private func formatSecondsToHMS(time: Double) -> String {
        if time.isInfinite || time.isNaN {
            return "00:00"
        }
        let secondsInt = Int(time)
        return NSString(format: "%02d:%02d", secondsInt / 60, secondsInt % 60) as String
    }
    private func calculateProgressWidth() {
        if progressViewFullWidth > .zero {
            let timePercent = CGFloat((currentTime / duration) * 100)
            if !timePercent.isNaN {
                progressWidth = max((timePercent / 100) * progressViewFullWidth, AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH)
            }
        }
    }
    private func getTimeFromProgressWidth() -> Double {
        let widthPercent = Double((progressWidth / progressViewFullWidth) * 100)
        let secondsToSeek: Double = (widthPercent / 100) * duration
        return secondsToSeek
    }
    private func checkBarMinimizeState(_ prevTime: Double) {
        if !self.barsMinimized && self.barShowTime >= AppConfig.MediaValues.PLAYER_MINIMIZE_TIME {
            if self.showTopMenu {
                self.showTopMenu = false
            }
            withAnimation(.easeInOut) {
                self.barsMinimized = true
            }
        }
        if !barsMinimized && isPlaying && !preventBarsHide && !showTopMenu && !isSeeking {
            let addInterval = currentTime - prevTime
            self.barShowTime += min(max(0, addInterval), 0.5)
        } else if self.barShowTime != .zero {
            resetBarShowTime()
        }
    }
    func resetBarShowTime() {
        self.barShowTime = .zero
    }
    func rotateScreen() -> Void {
        let value: Int
        if self.isFullscreen {
            value = UIInterfaceOrientation.landscapeRight.rawValue
        } else {
            value = UIInterfaceOrientation.portrait.rawValue
        }
        withAnimation(.linear) {
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }
    func dismissPlayer() {
        pausePlayer()
        removePeriodicTimeObserver()
        self.player?.replaceCurrentItem(with: nil)
    }
}
