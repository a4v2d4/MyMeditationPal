# MyMeditationPal 🧘‍♂️

A beautiful, Headspace-inspired iOS meditation and breathing exercise app built with SwiftUI.

## Features

### 📱 Main Dashboard
- Clean, calming interface with two daily exercise cards
- Video thumbnails auto-generated from your guided exercises
- Separate streak tracking for meditation and breathing exercises
- Checkboxes that auto-complete when videos finish
- Today's date prominently displayed

### 🎥 Video Player
- Full-screen video playback with sound
- Automatic completion tracking - only marks complete when video finishes
- Smooth transitions and animations
- **Celebration screen** appears after completion showing your streak progress

### 📅 Calendar History View
- Monthly calendar showing your practice history
- Green checkmarks for completed days
- Separate indicators for meditation (orange) and breathing (blue) exercises
- Navigate through past months
- Visual streak tracking

### 🔥 Streak System
- Independent streak tracking for meditation and breathing
- Streaks reset at midnight daily
- Streaks reset to 0 if you miss a day
- Persistent tracking using Core Data
- **Congratulatory screens** display after completing exercises, showing current streak
- Beautiful animations and encouraging messages to celebrate progress
- Different milestone celebrations (first day, weekly, monthly achievements)

## Design

Inspired by Headspace's aesthetic with:
- Soft, calming color palette (orange, peach, blue)
- Rounded cards with subtle shadows
- Clean typography
- Smooth animations and transitions
- Modern iOS design patterns

## Technical Stack

- **SwiftUI** - Modern declarative UI
- **Core Data** - Persistent storage for completion history
- **AVKit** - Video playback with completion detection
- **AVFoundation** - Video thumbnail generation

## Project Structure

```
MyMeditationPal/
├── Models/
│   └── ExerciseType.swift          # Exercise types and metadata
├── ViewModels/
│   └── MeditationViewModel.swift   # Business logic and data management
├── Views/
│   ├── DashboardView.swift         # Main screen
│   ├── ExerciseCardView.swift      # Reusable exercise card
│   ├── VideoPlayerView.swift       # Full-screen video player
│   ├── CalendarHistoryView.swift   # History calendar
│   ├── CongratulationsView.swift   # Celebration screen for exercises
│   ├── JournalCongratulationsView.swift # Celebration screen for journals
│   ├── MorningJournalView.swift    # Morning journaling
│   ├── NightJournalView.swift      # Night journaling
│   └── ... (other views)
├── Theme.swift                      # App-wide color scheme and styling
├── Persistence.swift                # Core Data stack
├── MyMeditationPal.xcdatamodeld/   # Core Data model
└── Video files (.mp4)               # Meditation and breathing exercises
```

## Core Data Model

**DailyCompletion** entity tracks:
- `date` - The day of completion (start of day)
- `meditationCompleted` - Boolean for meditation completion
- `breathingCompleted` - Boolean for breathing exercise completion

## How It Works

1. **Daily Reset**: App checks if checkboxes should reset at midnight
2. **Video Playback**: Tapping a card launches full-screen video player
3. **Completion Detection**: Video player monitors playback and only marks complete when video reaches the end
4. **Celebration**: Upon completion, a congratulatory screen appears showing your current streak with animations and encouraging messages
5. **Streak Calculation**: ViewModel calculates consecutive days of completion
6. **History View**: Calendar displays all past completions with color-coded indicators

## Adding New Videos

To add or replace videos:
1. Add `.mp4` files to the `MyMeditationPal` folder
2. Update `ExerciseType.swift` with the new video file names
3. Videos are automatically bundled with the app

## Requirements

- iOS 18.2+
- Xcode 16.2+
- Swift 5.0+

## Building & Running

1. Open `MyMeditationPal.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press Cmd+R to build and run

## Future Enhancements

Potential features to add:
- Customizable video rotations
- Reminders/notifications
- Additional exercise types
- Progress analytics
- iCloud sync
- Apple Watch companion app
- Siri shortcuts

---

Built with ❤️ for mindful living
