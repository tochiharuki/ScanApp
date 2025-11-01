import SwiftUI


struct SettingsView: View {
    // Save the selected retention period in UserDefaults
    @AppStorage("trashRetentionDays") private var retentionDays: Int = 30
    
    // 既存の日数オプション
    private let options: [Int] = [0, 10, 30, 60]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trash Settings")) {
                    Picker("File retention period (days)", selection: $retentionDays) {
                        ForEach(options, id: \.self) { days in
                            Text(days == 0 ? "0 days (Delete immediately)" : "\(days) days")
                                .tag(days)
                        }
                        // 追加：削除しないオプション
                        Text("Do not delete trash files")
                            .tag(-1)  // 特殊な値として -1 を使用
                    }
                    .pickerStyle(.menu)
                    .onChange(of: retentionDays) { newValue in
                        if newValue == -1 {
                            print("🗑 Trash files will never be deleted automatically")
                        } else {
                            print("🗑 Trash retention set to \(newValue) days")
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
        }
    }
}