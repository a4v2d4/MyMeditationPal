//
//  ExerciseType.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import Foundation

enum ExerciseType: Identifiable {
    case boxBreathing
    case meditation
    case coherentBreathing
    case bodyScan
    
    var id: String {
        switch self {
        case .boxBreathing:
            return "boxBreathing"
        case .meditation:
            return "meditation"
        case .coherentBreathing:
            return "coherentBreathing"
        case .bodyScan:
            return "bodyScan"
        }
    }
    
    var title: String {
        switch self {
        case .boxBreathing:
            return "Box Breath Exercise"
        case .meditation:
            return "Daily Meditation"
        case .coherentBreathing:
            return "Coherent Breath Exercise"
        case .bodyScan:
            return "Body Scan Meditation"
        }
    }
    
    var mediaFileName: String {
        switch self {
        case .boxBreathing:
            return "deepbreaths1min"
        case .meditation:
            return "Single - Guided 10min"
        case .coherentBreathing:
            return "HRV-5min-coherence"
        case .bodyScan:
            return "10minbodyscan"
        }
    }
    
    var mediaExtension: String {
        switch self {
        case .boxBreathing:
            return "mp4"
        case .meditation:
            return "mp3"
        case .coherentBreathing:
            return "mp4"
        case .bodyScan:
            return "mp4"
        }
    }
    
    var isAudioOnly: Bool {
        switch self {
        case .meditation:
            return true
        default:
            return false
        }
    }
    
    var duration: String {
        switch self {
        case .boxBreathing:
            return "1 min"
        case .meditation:
            return "10 min"
        case .coherentBreathing:
            return "5 min"
        case .bodyScan:
            return "10 min"
        }
    }
}
