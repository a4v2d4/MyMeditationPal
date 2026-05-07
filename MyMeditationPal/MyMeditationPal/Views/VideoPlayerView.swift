//
//  VideoPlayerView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI
import AVKit
import MediaPlayer

// Holds a weak reference to the AVPlayerViewController so VideoPlayerView can
// detach/reattach the AVPlayer around lifecycle transitions. This is the standard
// workaround for AVPlayerViewController auto-pausing video playback on screen lock
// even when audiovisualBackgroundPlaybackPolicy is .continuesIfPossible.
final class PlayerControllerHolder: ObservableObject {
    weak var controller: AVPlayerViewController?
}

// Custom video player wrapper that supports background audio
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let holder: PlayerControllerHolder
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        // PiP attempts to activate on screen lock and can't render, which causes iOS
        // to pause playback as a fallback. Disable it so background audio is uninterrupted.
        controller.allowsPictureInPicturePlayback = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        // Provide an initial frame to avoid "Invalid frame dimension" warnings from
        // AVPlayerViewController's internal layout before SwiftUI assigns proper bounds.
        controller.view.frame = UIScreen.main.bounds
        DispatchQueue.main.async {
            holder.controller = controller
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Don't reassign uiViewController.player here — VideoPlayerView manages
        // attachment manually around background/foreground transitions to keep
        // audio playing on the lock screen.
    }
}

struct VideoPlayerView: View {
    let exerciseType: ExerciseType
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var hasReachedEnd = false
    @State private var playCount = 0
    @State private var showingExitConfirmation = false
    @State private var showingCongratulations = false
    @State private var currentStreak = 0
    @StateObject private var controllerHolder = PlayerControllerHolder()
    
    // Audio playback controls state
    @State private var isPlaying = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                if exerciseType.isAudioOnly {
                    // Audio-only player with mic icon and controls
                    VStack(spacing: 40) {
                        Spacer()
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(exerciseType.title)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(exerciseType.duration)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        // Playback controls
                        VStack(spacing: 20) {
                            // Progress slider
                            VStack(spacing: 8) {
                                Slider(value: Binding(
                                    get: { currentTime },
                                    set: { newValue in
                                        currentTime = newValue
                                        player.seek(to: CMTime(seconds: newValue, preferredTimescale: 600))
                                    }
                                ), in: 0...max(duration, 0.1))
                                    .accentColor(.white)
                                
                                HStack {
                                    Text(formatTime(currentTime))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text(formatTime(duration))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 32)
                            
                            // Control buttons
                            HStack(spacing: 50) {
                                // Skip backward 10 seconds
                                Button(action: {
                                    skipBackward()
                                }) {
                                    Image(systemName: "gobackward.10")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                                
                                // Play/Pause button
                                Button(action: {
                                    togglePlayPause()
                                }) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(.white)
                                }
                                
                                // Skip forward 10 seconds
                                Button(action: {
                                    skipForward()
                                }) {
                                    Image(systemName: "goforward.10")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.bottom, 60)
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                } else {
                    // Video player with background audio support
                    CustomVideoPlayer(player: player, holder: controllerHolder)
                        .ignoresSafeArea()
                        .onDisappear {
                            cleanupPlayer()
                        }
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            // Exit button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showingExitConfirmation = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 44, height: 44)
                            )
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
            // Ensure audio session remains active when entering background
            setupBackgroundAudioHandling()
        }
        .alert("Exit Exercise?", isPresented: $showingExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                exitWithoutCompleting()
            }
        } message: {
            Text("Exiting now won't count this session as completed. You can always try again later!")
        }
        .fullScreenCover(isPresented: $showingCongratulations) {
            CongratulationsView(
                exerciseType: exerciseType,
                streak: currentStreak,
                onDismiss: {
                    showingCongratulations = false
                    dismiss()
                }
            )
        }
    }
    
    private func setupPlayer() {
        guard let mediaURL = Bundle.main.url(forResource: exerciseType.mediaFileName, withExtension: exerciseType.mediaExtension) else {
            print("Media file not found: \(exerciseType.mediaFileName).\(exerciseType.mediaExtension)")
            return
        }
        
        // Configure audio session for background playback
        configureAudioSession()
        
        let playerItem = AVPlayerItem(url: mediaURL)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Must be set before play() so audio continues when screen locks
        newPlayer.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        newPlayer.allowsExternalPlayback = true
        newPlayer.appliesMediaSelectionCriteriaAutomatically = true
        
        self.player = newPlayer
        
        // Observe when media ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            mediaDidFinish()
        }
        
        // Get duration
        if let currentItem = newPlayer.currentItem {
            let durationSeconds = CMTimeGetSeconds(currentItem.asset.duration)
            if durationSeconds.isFinite {
                duration = durationSeconds
            }
        }
        
        // Add time observer for progress tracking
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak newPlayer] time in
            guard let player = newPlayer else { return }
            let timeSeconds = CMTimeGetSeconds(time)
            if timeSeconds.isFinite {
                currentTime = timeSeconds
            }
            
            // Update duration if not set yet
            if duration == 0, let currentItem = player.currentItem {
                let durationSeconds = CMTimeGetSeconds(currentItem.asset.duration)
                if durationSeconds.isFinite {
                    duration = durationSeconds
                }
            }
            
            // Sync isPlaying state with actual player rate (important for video controls)
            let playerIsPlaying = player.rate > 0
            if isPlaying != playerIsPlaying {
                isPlaying = playerIsPlaying
            }
            
            // Update now playing info with current time
            updateNowPlayingInfo()
        }
        
        // Set up remote command handlers for lock screen controls
        setupRemoteCommandCenter()
        
        // Set up now playing info
        setupNowPlayingInfo()
        
        // Start playing
        newPlayer.play()
        isPlaying = true
    }
    
    private func mediaDidFinish() {
        playCount += 1
        
        // Check if we need to loop (for 10-minute coherent breathing)
        if exerciseType.shouldLoop && playCount == 1 {
            // Loop the video one more time
            player?.seek(to: .zero)
            player?.play()
        } else {
            hasReachedEnd = true
            // Save and recalculate streaks on a background thread so the main thread
            // stays free to animate the transition to the congratulations screen.
            viewModel.markCompletedInBackground(exerciseType: exerciseType) { streak in
                // Callback is already dispatched to the main queue.
                currentStreak = streak
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingCongratulations = true
                }
            }
        }
    }
    
    private func getStreakForExerciseType() -> Int {
        switch exerciseType {
        case .boxBreathing:
            return viewModel.boxBreathingStreak
        case .meditation(_):
            return viewModel.meditationStreak
        case .coherentBreathing(_):
            return viewModel.coherentBreathingStreak
        case .bodyScan:
            return viewModel.bodyScanStreak
        case .kegelExercise:
            return viewModel.kegelExerciseStreak
        }
    }
    
    private func cleanupPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
        
        // Clean up remote command center
        cleanupRemoteCommandCenter()
        
        // Clear now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    private func exitWithoutCompleting() {
        cleanupPlayer()
        dismiss()
    }
    
    // MARK: - Playback Controls
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            activateAudioSession()
            player.play()
        }
        isPlaying.toggle()
        updateNowPlayingPlaybackRate()
    }
    
    private func activateAudioSession() {
        // Reactivate the audio session before resuming. iOS may deactivate it
        // when the app is suspended in the background, and play() on a deactivated
        // session advances the playhead silently.
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func skipBackward() {
        guard let player = player else { return }
        let newTime = max(currentTime - 10, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
        updateNowPlayingInfo()
    }
    
    private func skipForward() {
        guard let player = player else { return }
        let newTime = min(currentTime + 10, duration)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
        updateNowPlayingInfo()
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        guard timeInSeconds.isFinite && timeInSeconds >= 0 else {
            return "0:00"
        }
        
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Background Audio & Lock Screen Controls
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // .default mode is required for both audio and video — .moviePlayback
            // causes iOS to silence the audio track when the screen locks
            let mode: AVAudioSession.Mode = .default
            try audioSession.setCategory(.playback, mode: mode, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupBackgroundAudioHandling() {
        // Observe audio session interruptions
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            if type == .began {
                self.isPlaying = false
            } else if type == .ended {
                try? AVAudioSession.sharedInstance().setActive(true)
                self.player?.play()
                self.isPlaying = true
                self.updateNowPlayingPlaybackRate()
            }
        }
        
        // When the app enters the background (screen lock or home button),
        // AVPlayerViewController will pause video playback even with
        // audiovisualBackgroundPlaybackPolicy set. Detach the player from the
        // controller so the AVPlayer can keep producing audio independently.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard let player = self.player, self.isPlaying else { return }
                if player.rate == 0 {
                    self.controllerHolder.controller?.player = nil
                    try? AVAudioSession.sharedInstance().setActive(true)
                    player.play()
                }
            }
        }
        
        // When the app returns to the foreground, reattach the player to the
        // controller so the video resumes rendering, and reactivate the audio
        // session in case it was deactivated while suspended.
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            try? AVAudioSession.sharedInstance().setActive(true)
            if let vc = self.controllerHolder.controller, let player = self.player, vc.player == nil {
                vc.player = player
            }
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            guard let player = self.player else { return .commandFailed }
            self.activateAudioSession()
            player.play()
            self.isPlaying = true
            self.updateNowPlayingPlaybackRate()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            guard let player = self.player else { return .commandFailed }
            player.pause()
            self.isPlaying = false
            self.updateNowPlayingPlaybackRate()
            return .success
        }
        
        // Toggle play/pause
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            self.togglePlayPause()
            return .success
        }
        
        // Skip forward
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { _ in
            self.skipForward()
            return .success
        }
        
        // Skip backward
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { _ in
            self.skipBackward()
            return .success
        }
    }
    
    private func cleanupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
    }
    
    private func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = exerciseType.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "MyMeditationPal"
        
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingInfo() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            setupNowPlayingInfo()
            return
        }
        
        if duration > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingPlaybackRate() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            setupNowPlayingInfo()
            return
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
