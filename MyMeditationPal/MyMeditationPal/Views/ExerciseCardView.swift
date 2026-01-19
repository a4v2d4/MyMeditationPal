//
//  ExerciseCardView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI
import AVFoundation

struct ExerciseCardView: View {
    let exerciseType: ExerciseType
    let isCompleted: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                ZStack {
                    if exerciseType.isAudioOnly {
                        // Audio-only exercise thumbnail
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.primaryOrange, Theme.primaryOrange.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.9))
                    } else if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Theme.mediumGray)
                            .frame(height: 180)
                        
                        ProgressView()
                    }
                    
                    // Play overlay
                    if !isCompleted {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.primaryOrange)
                    }
                }
                
                // Info section
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exerciseType.title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(exerciseType.duration)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Checkbox
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? Theme.successGreen : Theme.mediumGray, lineWidth: 2)
                            .frame(width: 32, height: 32)
                        
                        if isCompleted {
                            Circle()
                                .fill(Theme.successGreen)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(Theme.spacing)
            }
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isCompleted)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        // Skip thumbnail generation for audio-only exercises
        guard !exerciseType.isAudioOnly else {
            return
        }
        
        guard let videoURL = Bundle.main.url(forResource: exerciseType.mediaFileName, withExtension: exerciseType.mediaExtension) else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            } catch {
                print("Error generating thumbnail: \(error)")
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
