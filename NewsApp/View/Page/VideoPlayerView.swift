//
//  VideoPlayerView.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/10/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import SwiftUI
import Combine
import AVKit

struct VideoPlayerView: View {
    @ObservedObject
    var viewModel: PlayerViewModel
    let dismissPlayer: () -> Void
    private var safeSize: CGFloat {
        return (safeEdges?.top ?? 0) + (safeEdges?.bottom ?? 0)
    }
    var fitSize: CGSize {
        if viewModel.videoRectSize.width > .zero && viewModel.videoRectSize.height > .zero {
            if viewModel.layerRect.width > viewModel.layerRect.height {
                return CGSize(width: viewModel.layerRect.height * (viewModel.videoRectSize.width / viewModel.videoRectSize.height), height: viewModel.layerRect.height)
            } else {
                return CGSize(width: viewModel.layerRect.width, height: viewModel.layerRect.width / (viewModel.videoRectSize.width / viewModel.videoRectSize.height))
            }
        }
        return CGSize(width: viewModel.layerRect.width, height: viewModel.layerRect.width / DefaultAppConfig.projectAspectRatio)
    }
    @GestureState
    private var dismissTranslationActive = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .opacity(viewModel.layerOpacity)
                    .animation(.easeInOut, value: viewModel.layerOpacity)
                ZStack {
                    AVPlayerView(playerModel: viewModel)
                        .onDisappear(perform: onVideoPlayerDisappear)
                    if let posterImage = viewModel.posterImage, !viewModel.canDisplay {
                        Image(uiImage: posterImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .blur(radius: 5)
                            .transition(.opacity)
                            .zIndex(2)
                            //.contentShape(Rectangle())
                    }
                    // Control Layer
                    VideoControlLayer(viewModel: viewModel)
                }
                .frame(width: viewModel.isFullscreen
                                ? geo.size.width - viewModel.safeAreaSize
                                : geo.size.width,
                       height: geo.size.height)
                .animation(.easeInOut, value: viewModel.isFullscreen)
            }
            .offset(y: viewModel.dismissDragOffsetY)
            .animation(.easeInOut, value: viewModel.dismissDragOffsetY)
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .named("VideoControlLayer")).updating($dismissTranslationActive) { (_, state, _) in
                    state = true
                }
                    .onChanged(videoDismissDragUpdate(value:))
                    .onEnded(videoDismissDragEnd(value:))
            )
            .ignoresSafeArea()
            .onRotate { newOrientation in
                viewModel.isFullscreen = newOrientation == .landscapeLeft || newOrientation == .landscapeRight
                viewModel.resetBarShowTime()
            }
            .onChange(of: dismissTranslationActive) { dragIsActive in
                if !dragIsActive && viewModel.dismissDragOffsetY != .zero {
                    self.viewModel.dismissDragOffsetY = .zero
                }
            }
            .onChange(of: viewModel.canPlay) { canPlay in
                viewModel.playImmediately()
            }
            .onChange(of: viewModel.isFullscreen) { isFullscreen in
                viewModel.layerRect = geo.size
                if isFullscreen {
                    viewModel.safeAreaSize = (safeEdges?.left ?? 0) + (safeEdges?.right ?? 0)
                } else {
                    viewModel.safeAreaSize = (safeEdges?.top ?? 0) + (safeEdges?.bottom ?? 0)
                }
            }
            // MARK: Bug. Sometimes it won't be called. Use onDisappear instead
            .onChange(of: viewModel.closePlayer) { close in
                if close {
                    dismissPlayer()
                }
            }
            .onAppear {
                viewModel.layerRect = geo.size
                viewModel.safeAreaSize = (safeEdges?.top ?? 0) + (safeEdges?.bottom ?? 0)
                if let shareUrl = viewModel.shareUrl {
                    FAnalyticsService.shared.sendScreenView(shareUrl.absoluteString, className: String(describing: VideoPlayerView.self))
                }
            }
        }
        .ignoresSafeArea()
    }
    private func onVideoPlayerDisappear() {
        if viewModel.isFullscreen {
            viewModel.isFullscreen.toggle()
            viewModel.rotateScreen()
        }
        viewModel.dismissPlayer()
        dismissPlayer()
    }
    private func videoDismissDragUpdate(value: DragGesture.Value) {
        let newY = max(value.translation.height, .zero)
        self.viewModel.dismissDragOffsetY = newY
        DispatchQueue.main.async {
            if newY >= (viewModel.layerRect.dragCloseOffset ?? AppConfig.GestureValues.DRAG_DISMISS_OFFSET) && !viewModel.playerPaused() {
                viewModel.pausePlayer()
            }
            self.viewModel.layerOpacity = newY.opacityProgress
        }
    }
    private func videoDismissDragEnd(value: DragGesture.Value) {
        self.viewModel.layerOpacity = 1
        let translation = value.translation.height
        if translation >= (viewModel.layerRect.dragCloseOffset ?? AppConfig.GestureValues.DRAG_DISMISS_OFFSET) {
            self.viewModel.closePlayer = true
        } else {
            self.viewModel.dismissDragOffsetY = .zero
            if viewModel.playerPaused() {
                viewModel.startPlay(notStartIfManual: true)
            }
        }
    }
}

struct AVPlayerControllerView: UIViewControllerRepresentable {
    @ObservedObject
    var playerModel: PlayerViewModel
    var playerLayer = AVPlayerLayer()
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        controller.player = playerModel.player
        controller.showsPlaybackControls = false
        controller.view.backgroundColor = UIColor(Color.clear)
        
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}

struct VideoControlLayer: View {
    @ObservedObject
    var viewModel: PlayerViewModel
    @EnvironmentObject
    var stateVM: StateViewModel
    @StateObject
    private var downloadTask = DownloadTaskModel()
    private let saveVideoHandler: (PlayerViewModel, DownloadTaskModel) -> () = { (vM, dT) in
        vM.pausePlayer()
        vM.preventBarsHide = true
        if let videoFileUrl = vM.videoFileUrl {
            dT.saveRemoteVideo(videoFileUrl, fileType: .video) {
                vM.preventBarsHide = false
                // Show Share dialog for video
                dT.downloadedUrl?.shareSheet()
            }
        }
    }
    @Namespace var namespace
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            if !viewModel.barsMinimized {
                VideoPlayerTopBar(viewModel: viewModel, namespace: namespace)
            }
            // Content
            Color.clear
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .coordinateSpace(name: "VideoControlLayer")
                .gesture(TapGesture()
                    .onEnded {
                        withAnimation(.easeInOut) {
                            if viewModel.showTopMenu {
                                viewModel.showTopMenu.toggle()
                            } else if !viewModel.showPlayError && !downloadTask.isDownloading {
                                viewModel.barsMinimized.toggle()
                            }
                        }
                    })
                .overlay(viewModel.showTopMenu
                            ? PlayerMenuView(playerModel: viewModel, downloadTask: downloadTask, namespace: namespace, saveVideoHandler: saveVideoHandler)
                                .padding(.trailing, 10)
                            : nil, alignment: .topTrailing)
            // Bottom Control
            if !viewModel.barsMinimized {
                VideoPlayerControlBar(playerModel: viewModel, downloadTask: downloadTask, saveVideoHandler: saveVideoHandler)
            } else {
                VideoProgressBar(playerModel: viewModel)
            }
        }
        .onChange(of: viewModel.presentReportAlert, perform: presentReportAlertFromVideo)
        .onChange(of: downloadTask.alertState) { state in
            if state != .none {
                stateVM.presentAlert(contentItem: SheetAlertContent(title: AlertText(text: "allow_access"), message: AlertText(text: "add_photo_access_description", textFont: .callout, textWeight: .regular), dismissBtn: CustomAlertButton(text: "not_now", textWeight: .semibold, type: .defaultBtn, action: dismissDownloadPermissionAlert), actionBtn: CustomAlertButton(text: "settings", type: .defaultBtn, action: {
                    dismissDownloadPermissionAlert()
                    stateVM.openAppSettings()
                })))
            }
        }
    }
    private func presentReportAlertFromVideo(show: Bool) {
        withAnimation(.easeInOut) {
            if show {
                stateVM.presentAlert(contentItem: SheetAlertContent(title: AlertText(text: "report"), message: AlertText(text: "enter_problem_message", textFont: .body, textWeight: .regular), messageType: .editable, dismissBtn: CustomAlertButton(text: "cancel", type: .defaultBtn, action: dismissReportAlertOnVideo), actionBtn: CustomAlertButton(text: "send", textWeight: .semibold, type: .cancelBtn, action: reportFromVideoAction), forPage: .video))
            } else {
                dismissReportAlertOnVideo()
                stateVM.dismissAlert()
            }
        }
    }
    private func dismissReportAlertOnVideo() {
        self.viewModel.presentReportAlert = false
    }
    private func dismissDownloadPermissionAlert() {
        downloadTask.alertState = .none
    }
    private func reportFromVideoAction() {
        self.stateVM.sendReport(page: viewModel.parentId, issueItem: viewModel.videoFileUrl?.absoluteString ?? "#")
    }
}

struct VideoPlayerTopBar: View {
    @ObservedObject
    var viewModel: PlayerViewModel
    let namespace: Namespace.ID
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: {
                self.viewModel.closePlayer = true
            }, label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18))
                        
                    Text("back")
                        .font(.system(size: 16))
                }
            })
            Spacer()
            Button(action: {
                withAnimation(.linear(duration: 0.2)) {
                    viewModel.showTopMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .background( !viewModel.showTopMenu ?
                        Color.clear
                            .matchedGeometryEffect(id: "topMenuBg", in: namespace, properties: .position)
                            .matchedGeometryEffect(id: "topMenuRow0", in: namespace, properties: .position)
                            .matchedGeometryEffect(id: "topMenuRow1", in: namespace, properties: .position)
                            .matchedGeometryEffect(id: "topMenuRow2", in: namespace, properties: .position) : nil
                    )
            }
        }
        .padding(.top, viewModel.isFullscreen ? 6 :(safeEdges?.top ?? 14))
        .padding(.bottom, viewModel.isFullscreen ? 6 : 10)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(AppConfig.MediaValues.BLACK_BG_OPACITY))
        .foregroundColor(.white)
    }
}
struct VideoPlayerControlBar: View {
    @ObservedObject
    var playerModel: PlayerViewModel
    @StateObject
    var downloadTask: DownloadTaskModel
    let saveVideoHandler: (PlayerViewModel, DownloadTaskModel) -> ()
    private var safeSize: CGFloat {
        return (safeEdges?.top ?? 0) + (safeEdges?.bottom ?? 0)
    }
    var body: some View {
        VStack(spacing: 0) {
            if downloadTask.isDownloading {
                downloadView
            } else if playerModel.showPlayError {
                Text(LocalizedStringKey(playerModel.playErrorMsg ?? "video_play_error"))
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                Text("try_open_video")
                    .font(.callout)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let shareUrl = playerModel.shareUrl {
                    Text("\(shareUrl)")
                        .font(.callout)
                        .underline()
                        .lineLimit(1)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                        Button(action: {
                            if UIApplication.shared.canOpenURL(shareUrl) {
                                UIApplication.shared.open(shareUrl)
                            }
                        }) {
                            Text("open")
                                .font(.callout)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(Color("BlackGrey"))
                                .clipShape(RoundedRectangle(cornerRadius: 4.0))
                        }, alignment: .trailing)
                }
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 10)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: playerModel.isFullscreen ? 4 : 16)
            }
            
            // Progress bar
            HStack(spacing: 8) {
                if playerModel.isFullscreen {
                    Text("\(playerModel.getCurrentTime())")
                        .font(.system(size: 14))
                }
                ZStack(alignment: .leading) {
                    // Default progress
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear() {
                                        playerModel.progressViewFullWidth = geo.size.width
                                    }
                                    .onChange(of: playerModel.isFullscreen) { _ in
                                        playerModel.progressViewFullWidth = geo.size.width < playerModel.layerRect.width ? geo.size.width : playerModel.layerRect.width
                                    }
                            }
                        )
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: playerModel.progressWidth.isNormal ? playerModel.progressWidth : AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH)
                        .animation(playerModel.progressWidth == AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH ? nil : .easeInOut(duration: playerModel.progressAnimationTime), value: playerModel.progressWidth)
                        .overlay(
                            //scrubber
                            ScrubberView(playerModel: playerModel)
                            , alignment: .trailing
                        )
                }
                .frame(height: 4)
                if playerModel.isFullscreen {
                    Text("\(playerModel.getDuration())")
                        .font(.system(size: 14))
                }
            }
            // Duration bar
            if !playerModel.isFullscreen {
                HStack {
                    Text("\(playerModel.getCurrentTime())")
                        .font(.callout)
                    Spacer()
                    Text("\(playerModel.getDuration())")
                        .font(.callout)
                }
                .padding(.top, 8)
            }
            ControlBottomButton(playerModel: playerModel, downloadTask: downloadTask, saveVideoHandler: saveVideoHandler)
        }
        .padding(.bottom, playerModel.isFullscreen ? 14 : (safeEdges?.bottom ?? 14))
        .padding(.horizontal, 10)
        .frame(alignment: .bottom)
        .background(Color.black.opacity(AppConfig.MediaValues.BLACK_BG_OPACITY))
        .foregroundColor(.white)
    }
    var downloadView: some View {
        HStack(spacing: 0) {
            if downloadTask.showDownloadError {
                Text("error_save_video")
                    .font(.caption)
                Button(action: {
                    saveVideoHandler(playerModel, downloadTask)
                }) {
                    Text("retry")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .underline()
                }
            } else {
                Text("\(downloadTask.downloadProgress)%")
                    .fontWeight(.semibold)
                Text("downloading")
                    .fontWeight(.semibold)
                    .padding(.leading, 6)
                    .padding(.vertical, 14)
            }
            Spacer(minLength: 0)
            Button(action: cancelVideoDownload) {
                Text("cancel")
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 8)
        }
        .font(.system(size: 16))
    }
    func cancelVideoDownload() {
        downloadTask.cancelDownload()
        playerModel.playPause(manually: false)
    }
}
fileprivate struct ControlBottomButton: View {
    @ObservedObject
    var playerModel: PlayerViewModel
    @StateObject
    var downloadTask: DownloadTaskModel
    let saveVideoHandler: (PlayerViewModel, DownloadTaskModel) -> ()
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: videoUrlShare) {
                Image(systemName: "arrowshape.turn.up.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 20, alignment: .leading)
            }
            .padding(.vertical, 4)
            
            Spacer(minLength: 0)
            
            Button(action: {
                playerModel.playPause(manually: true)
            }, label: {
                Image(systemName: !playerModel.playerPaused() ? "pause.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: playerModel.isFullscreen ? 22 : 26)
                    .padding(.vertical, playerModel.isFullscreen ? 4 : 8)
                    .padding(.horizontal, 14)
            })
            
            Spacer(minLength: 0)
            
            if !playerModel.isVertical() {
                Button(action: toggleVideoFullscreen) {
                    Image(playerModel.isFullscreen ? "fullscreen_exit" : "fullscreen_enter")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
            } else if downloadTask.isDownloading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                    .frame(width: 32, height: 24)
            } else {
                Button(action: downloadVideoAction) {
                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 24)
                }
            }
        }
        .padding(.top, 6)
    }
    func videoUrlShare() {
        playerModel.pausePlayer()
        playerModel.shareUrl?.shareSheet()
    }
    func toggleVideoFullscreen() {
        playerModel.isFullscreen.toggle()
        playerModel.rotateScreen()
    }
    func downloadVideoAction() {
        saveVideoHandler(playerModel, downloadTask)
    }
}
struct VideoProgressBar: View {
    @ObservedObject
    var playerModel: PlayerViewModel
    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule()
                .fill(Color.clear)
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: playerModel.isFullscreen) { _ in
                                playerModel.progressViewFullWidth = geo.size.width < playerModel.layerRect.width ? geo.size.width : playerModel.layerRect.width
                            }
                    }
                )
            Capsule()
                .fill(Color.white.opacity(0.6))
                .frame(width: playerModel.progressWidth)
                .animation(playerModel.progressWidth == AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH ? nil : .easeInOut(duration: playerModel.progressAnimationTime), value: playerModel.progressWidth)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 2)
        .padding(.bottom, safeEdges?.bottom ?? 14)
        .padding(.bottom, playerModel.isFullscreen ? 2 : 15)
        .padding(.horizontal, 10)
    }
}
struct ScrubberView: View {
    @ObservedObject
    var playerModel: PlayerViewModel
    @State
    private var dragOffsetX: CGFloat = .zero
    @State
    private var scrubberWidth: CGFloat = AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: 36, height: 36)
            Circle()
            .fill(Color.white)
            .offset(x: dragOffsetX)
            .frame(width: scrubberWidth, height: scrubberWidth)
            .animation(.easeInOut(duration: 0.8), value: dragOffsetX)
            .animation(.easeInOut(duration: 0.8), value: scrubberWidth)
            .animation(playerModel.progressWidth == AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH ? nil : .easeInOut(duration: playerModel.progressAnimationTime), value: playerModel.progressWidth)
        }
        .frame(width: scrubberWidth, height: scrubberWidth)
        .gesture(
            DragGesture()
                .onChanged() { value in
                    self.playerModel.isSeeking = true
                    self.scrubberWidth = AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH * 2
                    let offsetX = value.translation.width
                    
                    let newProgressWidth: CGFloat
                    if offsetX < 0 {
                        newProgressWidth = (playerModel.progressWidth - abs(offsetX)) > 0
                            ? playerModel.progressWidth - abs(offsetX) : 0
                    } else {
                        newProgressWidth = (playerModel.progressWidth + offsetX)
                            > playerModel.progressViewFullWidth
                            ? playerModel.progressViewFullWidth
                            : playerModel.progressWidth + offsetX
                    }
                    self.playerModel.progressWidth = max(newProgressWidth, AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH)
                    self.dragOffsetX = .zero
                }
                .onEnded() { value in
                    self.scrubberWidth = AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH
                    self.playerModel.progressWidth = min(max(playerModel.progressWidth, AppConfig.MediaValues.PLAYER_PROGRESS_MIN_WIDTH), playerModel.progressViewFullWidth)
                    playerModel.seekToWidth()
                }
        )
    }
}
struct PlayerMenuView: View {
    //@StateObject
    @ObservedObject
    var playerModel: PlayerViewModel
    @StateObject
    var downloadTask: DownloadTaskModel
    let namespace: Namespace.ID
    let saveVideoHandler: (PlayerViewModel, DownloadTaskModel) -> ()
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                playerModel.showTopMenu.toggle()
                saveVideoHandler(playerModel, downloadTask)
            }) {
                HStack(spacing: 0) {
                    Text("save_video")
                        .font(.body)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                }
            }
            .matchedGeometryEffect(id: "topMenuRow0", in: namespace)
            .padding(.top, 18)
            .padding(.bottom, 18)
            .padding(.horizontal, 14)
            CustomDivider(width: .infinity, height: 1, color: Color.white.opacity(0.1))
                .matchedGeometryEffect(id: "topMenuRow1", in: namespace)
            Button(action: presentAlertFromMenu) {
                HStack(spacing: 0) {
                    Text("report")
                        .font(.body)
                    Spacer(minLength: 0)
                    Image(systemName: "exclamationmark.bubble")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                }
            }
            .matchedGeometryEffect(id: "topMenuRow2", in: namespace)
            .padding(.top, 16)
            .padding(.bottom, 18)
            .padding(.horizontal, 14)
        }
        .foregroundColor(.white)
        .frame(width: 250)
        .background(
            Color("BlackGrey").matchedGeometryEffect(id: "topMenuBg", in: namespace)
        )
        .cornerRadius(12)
    }
    private func presentAlertFromMenu() {
        playerModel.showTopMenu.toggle()
        playerModel.pausePlayer()
        playerModel.presentReportAlert = true
    }
    
}
enum PlayerGravity {
    case aspectFill
    case resize
}

struct AVPlayerView: UIViewRepresentable {
    @ObservedObject
    var playerModel: PlayerViewModel
    
    func makeUIView(context: Context) -> PlayerView {
        let playerView = PlayerView(player: playerModel.player, gravity: .aspectFill)
        
        playerView.playerLayer.publisher(for: \.isReadyForDisplay).sink { canDisplay in
            if canDisplay {
                withAnimation(.easeInOut) {
                    self.playerModel.canDisplay = canDisplay
                }
            }
        }
        .store(in: playerModel.cancelBag)
        
        return playerView
    }
    func updateUIView(_ uiView: PlayerView, context: Context) {
        if playerModel.isFullscreen {
            
        }
    }
}
class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    let gravity: PlayerGravity
    init(player: AVPlayer?, gravity: PlayerGravity) {
        self.gravity = gravity
        super.init(frame: .zero)
        self.player = player
        self.backgroundColor = .clear
        setupLayer()
    }
    func setupLayer() {
        switch gravity {
        case .aspectFill:
            playerLayer.contentsGravity = .resizeAspect
            playerLayer.videoGravity = .resizeAspect
        case .resize:
            playerLayer.contentsGravity = .resize
            playerLayer.videoGravity = .resize
            
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(viewModel: PlayerViewModel(videoPath: MediaPath(thumb: nil, sd: URL.init(string: ""), hd: nil), posterImage: nil, shareUrl: URL.init(string: ""), videoRect: CGSize.zero, parentId: "10_0", id: "1"), dismissPlayer: {})
    }
}
