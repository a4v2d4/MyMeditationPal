//
//  ExerciseType.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import Foundation

enum ExerciseType: Identifiable {
    case meditation
    case breathing
    
    var id: String {
        switch self {
        case .meditation:
            return "meditation"
        case .breathing:
            return "breathing"
        }
    }
    
    var title: String {
        switch self {
        case .meditation:
            return "Daily Meditation"
        case .breathing:
            return "Breathing Exercise"
        }
    }
    
    var videoFileName: String {
        switch self {
        case .meditation:
            return "GuidedMeditation-10min-reset"
        case .breathing:
            return "HRV-5min-coherence"
        }
    }
    
    var duration: String {
        switch self {
        case .meditation:
            return "10 min"
        case .breathing:
            return "5 min"
        }
    }
}
