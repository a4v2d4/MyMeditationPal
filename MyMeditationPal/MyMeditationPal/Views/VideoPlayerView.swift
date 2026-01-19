//
//  VideoPlayerView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let exerciseType: ExerciseType
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var hasReachedEnd = false
    @State private var playCount = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                if exerciseType.isAudioOnly {
                    // Audio-only player with mic icon
                    VStack(spacing: 40) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(exerciseType.title)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(exerciseType.duration)
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
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
        }
        .onAppear {
            setupPlayer()
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
        
        // Start playing
        newPlayer.play()
    }
    
    private func mediaDidFinish() {
        playCount += 1
        
        // Check if we need to loop (for 10-minute coherent breathing)
        if exerciseType.shouldLoop && playCount == 1 {
            // Loop the video one more time
            player?.seek(to: .zero)
            player?.play()
        } else {
            // Mark as completed and dismiss
            hasReachedEnd = true
            viewModel.markCompleted(exerciseType: exerciseType)
            
            // Delay dismiss slightly for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
