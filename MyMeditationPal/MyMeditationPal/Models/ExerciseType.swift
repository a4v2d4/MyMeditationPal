//
//  ExerciseType.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import Foundation

enum ExerciseType: Identifiable {
    case boxBreathing
    case meditation(duration: Int) // duration in minutes: 5 or 10
    case coherentBreathing(duration: Int) // duration in minutes: 5 or 10
    case bodyScan
    case kegelExercise
    
    var id: String {
        switch self {
        case .boxBreathing:
            return "boxBreathing"
        case .meditation(let duration):
            return "meditation_\(duration)"
        case .coherentBreathing(let duration):
            return "coherentBreathing_\(duration)"
        case .bodyScan:
            return "bodyScan"
        case .kegelExercise:
            return "kegelExercise"
        }
    }
    
    var title: String {
        switch self {
        case .boxBreathing:
            return "Box Breath Exercise"
        case .meditation(let duration):
            return "Daily Meditation (\(duration) min)"
        case .coherentBreathing(let duration):
            return "Coherent Breath Exercise (\(duration) min)"
        case .bodyScan:
            return "Body Scan Meditation"
        case .kegelExercise:
            return "Kegel Exercise"
        }
    }
    
    var mediaFileName: String {
        switch self {
        case .boxBreathing:
            return "deepbreaths1min"
        case .meditation(let duration):
            if duration == 5 {
                return "SelfCareGuidedMeditation-5min"
            } else {
                return "Single - Guided 10min"
            }
        case .coherentBreathing(let duration):
            return "HRV-\(duration)min-coherence"
        case .bodyScan:
            return "10minbodyscan"
        case .kegelExercise:
            return "KegelExercise2min"
        }
    }
    
    var mediaExtension: String {
        switch self {
        case .boxBreathing:
            return "mp4"
        case .meditation(_):
            return "mp3"
        case .coherentBreathing(_):
            return "mp4"
        case .bodyScan:
            return "mp4"
        case .kegelExercise:
            return "mp4"
        }
    }
    
    var isAudioOnly: Bool {
        switch self {
        case .meditation(_):
            return true
        default:
            return false
        }
    }
    
    var duration: String {
        switch self {
        case .boxBreathing:
            return "1 min"
        case .meditation(let duration):
            return "\(duration) min"
        case .coherentBreathing(let duration):
            return "\(duration) min"
        case .bodyScan:
            return "10 min"
        case .kegelExercise:
            return "2 min"
        }
    }
    
    var shouldLoop: Bool {
        switch self {
        case .coherentBreathing(let duration):
            return duration == 10 // Loop for 10 min option
        default:
            return false
        }
    }
}
