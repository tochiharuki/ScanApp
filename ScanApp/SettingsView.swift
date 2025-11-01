import SwiftUI

struct SettingsView: View {
    @AppStorage("trashRetentionDays") private var retentionDays: Int = 30
    
    private let options: [Int] = [0, 10, 30, 60]

    @State private var showAlert = false
    @State private var pendingRetentionDays: Int = 30  // ユーザーが選択した値を一時保存
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trash Settings")) {
                    Picker("File retention period (days)", selection: $pendingRetentionDays) {
                        ForEach(options, id: \.self) { days in
                            Text(days == 0 ? "0 days (Delete immediately)" : "\(days) days")
                                .tag(days)
                        }
                        Text("Do not delete trash files")
                            .tag(-1)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: pendingRetentionDays) { newValue in
                        // アラートを表示
                        if newValue != retentionDays {
                            showAlert = true
                        }
                    }
                }

                Section {
                    Text("Default retention period is 30 days.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Confirm Trash Cleanup"),
                    message: Text("Do you want to immediately remove trash files that exceed the new retention period?"),
                    primaryButton: .destructive(Text("Delete Now")) {
                        retentionDays = pendingRetentionDays
                        // ここで Trash 内の古いファイルを削除
                        cleanTrashImmediately()
                    },
                    secondaryButton: .cancel {
                        // ユーザーがキャンセルした場合は値を元に戻す
                        pendingRetentionDays = retentionDays
                    }
                )
            }
        }
    }

    private func cleanTrashImmediately() {
        let trashURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Trash")
        
        let now = Date()
        let files = (try? FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: [.creationDateKey])) ?? []
        
        for file in files {
            if let moveDate = UserDefaults.standard.object(forKey: file.lastPathComponent) as? Date {
                let days = Calendar.current.dateComponents([.day], from: moveDate, to: now).day ?? 0
                if days >= retentionDays {
                    try? FileManager.default.removeItem(at: file)
                    UserDefaults.standard.removeObject(forKey: file.lastPathComponent)
                    print("🗑 Deleted \(file.lastPathComponent) immediately due to retention change")
                }
            }
        }
    }
}