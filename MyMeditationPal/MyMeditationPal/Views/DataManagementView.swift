//
//  DataManagementView.swift
//  MyMeditationPal
//

import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var alertState: AlertState?
    
    private enum AlertState: Identifiable {
        case importSuccess(Int)
        case importFailure(String)
        case exportFailure(String)
        
        var id: String {
            switch self {
            case .importSuccess(let n): return "importSuccess\(n)"
            case .importFailure(let msg): return "importFailure\(msg)"
            case .exportFailure(let msg): return "exportFailure\(msg)"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerCard
                        exportCard
                        importCard
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Data Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.primaryOrange)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert(item: $alertState) { state in
                switch state {
                case .importSuccess(let count):
                    return Alert(
                        title: Text("Import Successful"),
                        message: Text("Restored \(count) day\(count == 1 ? "" : "s") of data."),
                        dismissButton: .default(Text("OK"))
                    )
                case .importFailure(let msg):
                    return Alert(
                        title: Text("Import Failed"),
                        message: Text(msg),
                        dismissButton: .default(Text("OK"))
                    )
                case .exportFailure(let msg):
                    return Alert(
                        title: Text("Export Failed"),
                        message: Text(msg),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.icloud")
                .font(.system(size: 44))
                .foregroundColor(Theme.primaryOrange)
            
            Text("Backup & Restore")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text("Export your journal entries, habit history, and activity streaks as a JSON file. Import a backup to restore your data.")
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
    
    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.primaryOrange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Data")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Save all your history as a JSON file")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Button(action: handleExport) {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                    Text("Export JSON")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .background(Theme.primaryOrange)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private var importCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.deepBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import Data")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Restore from a previously exported file")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Label("Existing records for the same day will be overwritten", systemImage: "exclamationmark.triangle")
                .font(.system(size: 12))
                .foregroundColor(Color.orange.opacity(0.8))
            
            Button(action: { isImporting = true }) {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.down")
                    Text("Import JSON")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .background(Theme.deepBlue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Actions
    
    private func handleExport() {
        do {
            let data = try viewModel.exportAllData()
            guard let url = makeExportFileURL(from: data) else { return }
            presentShareSheet(url: url)
        } catch {
            alertState = .exportFailure(error.localizedDescription)
        }
    }
    
    /// Present UIActivityViewController directly via UIKit to avoid the blank-sheet bug
    /// that occurs when UIActivityViewController is wrapped in a SwiftUI sheet.
    private func presentShareSheet(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // Walk to the topmost presented view controller
        var topVC = window.rootViewController
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        
        // iPad requires a popover source
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topVC?.present(activityVC, animated: true)
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            alertState = .importFailure(error.localizedDescription)
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try viewModel.importData(from: url)
                alertState = .importSuccess(count)
            } catch {
                alertState = .importFailure("Could not parse the file. Make sure it was exported from this app.\n\n\(error.localizedDescription)")
            }
        }
    }
    
    private func makeExportFileURL(from data: Data) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "MyMeditationPal-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            alertState = .exportFailure(error.localizedDescription)
            return nil
        }
    }
}

#Preview {
    DataManagementView(viewModel: MeditationViewModel())
}
