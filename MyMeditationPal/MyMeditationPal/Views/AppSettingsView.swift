//
//  AppSettingsView.swift
//  MyMeditationPal
//

import SwiftUI

// MARK: - Local palette for the dark settings screen

private extension Color {
    static let settingsBg      = Color(red: 0.11, green: 0.16, blue: 0.29)   // deep navy
    static let settingsCard    = Color(red: 0.16, green: 0.22, blue: 0.38)   // slightly lighter navy
    static let settingsDivider = Color.white.opacity(0.08)
}

struct AppSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.settingsBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        exercisesSection
                        journalsSection
                        habitsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.primaryOrange)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var exercisesSection: some View {
        SettingsSection(title: "Exercises", icon: "play.circle.fill") {
            SettingsToggleRow(icon: "lungs.fill",          iconColor: Theme.primaryOrange,                     label: "Box Breathing",      isOn: $settings.boxBreathingEnabled)
            SettingsToggleRow(icon: "figure.mind.and.body", iconColor: Color(red: 0.4, green: 0.75, blue: 0.65), label: "Daily Meditation",   isOn: $settings.meditationEnabled)
            SettingsToggleRow(icon: "waveform.path.ecg",   iconColor: Color(red: 0.4, green: 0.6,  blue: 0.9),  label: "Coherent Breathing", isOn: $settings.coherentBreathingEnabled)
            SettingsToggleRow(icon: "figure.cooldown",     iconColor: Color(red: 0.6, green: 0.45, blue: 0.9),  label: "Body Scan",          isOn: $settings.bodyScanEnabled)
            SettingsToggleRow(icon: "bolt.heart.fill",     iconColor: Color(red: 0.95, green: 0.4, blue: 0.5),  label: "Kegel Exercise",     isOn: $settings.kegelEnabled, isLast: true)
        }
    }

    private var journalsSection: some View {
        SettingsSection(title: "Journals", icon: "book.fill") {
            SettingsToggleRow(icon: "sun.max.fill",    iconColor: Color(red: 0.98, green: 0.80, blue: 0.3), label: "Morning Journal", isOn: $settings.morningJournalEnabled)
            SettingsToggleRow(icon: "moon.stars.fill", iconColor: Color(red: 0.45, green: 0.55, blue: 0.9), label: "Night Journal",   isOn: $settings.nightJournalEnabled, isLast: true)
        }
    }

    private var habitsSection: some View {
        SettingsSection(
            title: "Daily Habits",
            icon: "checklist",
            footer: settings.dailyHabitsEnabled ? "Disabled habits won't appear in your daily checklist." : nil
        ) {
            SettingsToggleRow(
                icon: "checkmark.circle.fill",
                iconColor: Theme.successGreen,
                label: "Daily Habits",
                isOn: $settings.dailyHabitsEnabled,
                isLast: !settings.dailyHabitsEnabled
            )

            if settings.dailyHabitsEnabled {
                ForEach(Array(DailyHabitsView.defaultHabits.enumerated()), id: \.element.id) { index, habit in
                    HabitSettingsRow(
                        habit: habit,
                        isLast: index == DailyHabitsView.defaultHabits.count - 1
                    )
                }
            }
        }
    }
}

// MARK: - Section container

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    var footer: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(0.8)
            }
            .foregroundColor(Theme.primaryOrange)
            .padding(.bottom, 10)

            // Card
            VStack(spacing: 0) {
                content
            }
            .background(Color.settingsCard)
            .cornerRadius(14)

            // Footer
            if let footer {
                Text(footer)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Toggle row

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.22))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.white)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(Theme.primaryOrange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if !isLast {
                Divider()
                    .background(Color.settingsDivider)
                    .padding(.leading, 64)
            }
        }
    }
}

// MARK: - Habit row

private struct HabitSettingsRow: View {
    @EnvironmentObject var settings: AppSettings
    let habit: DailyHabit
    var isLast: Bool = false

    var isEnabled: Bool { settings.isHabitEnabled(habit.id) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: isEnabled ? "circle.fill" : "circle")
                    .font(.system(size: 8))
                    .foregroundColor(isEnabled ? Theme.successGreen : .white.opacity(0.3))
                    .padding(.leading, 13)

                Text(habit.name)
                    .font(.system(size: 15))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.4))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { _ in settings.toggleHabit(habit.id) }
                ))
                .labelsHidden()
                .tint(Theme.primaryOrange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if !isLast {
                Divider()
                    .background(Color.settingsDivider)
                    .padding(.leading, 50)
            }
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(AppSettings())
}
