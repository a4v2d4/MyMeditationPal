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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onDisappear {
                        cleanupPlayer()
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
        guard let videoURL = Bundle.main.url(forResource: exerciseType.videoFileName, withExtension: "mp4") else {
            print("Video file not found: \(exerciseType.videoFileName)")
            return
        }
        
        let newPlayer = AVPlayer(url: videoURL)
        self.player = newPlayer
        
        // Observe when video ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            videoDidFinish()
        }
        
        // Start playing
        newPlayer.play()
    }
    
    private func videoDidFinish() {
        hasReachedEnd = true
        viewModel.markCompleted(exerciseType: exerciseType)
        
        // Delay dismiss slightly for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
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
