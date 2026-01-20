//
//  VideoPlayerView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI
import AVKit
import MediaPlayer

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
                    // Video player
                    VideoPlayer(player: player)
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
        
        let newPlayer = AVPlayer(url: mediaURL)
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
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
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
        }
        
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
            // Mark as completed
            hasReachedEnd = true
            viewModel.markCompleted(exerciseType: exerciseType)
            
            // Get the updated streak
            currentStreak = getStreakForExerciseType()
            
            // Show congratulations view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingCongratulations = true
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
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func skipBackward() {
        guard let player = player else { return }
        let newTime = max(currentTime - 10, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    private func skipForward() {
        guard let player = player else { return }
        let newTime = min(currentTime + 10, duration)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
        currentTime = newTime
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        guard timeInSeconds.isFinite && timeInSeconds >= 0 else {
            return "0:00"
        }
        
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
