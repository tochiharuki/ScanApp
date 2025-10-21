//
//  SettingsView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("App Settings")) {
                    Toggle("Enable OCR", isOn: .constant(true))
                    Toggle("Backup to iCloud", isOn: .constant(false))
                }

                Section {
                    Text("App Info")
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
