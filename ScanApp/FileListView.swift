//
//  FileListView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

struct FileListView: View {
    var body: some View {
        NavigationView {
            List {
                Text("No scanned documents yet.")
                    .foregroundColor(.black)
            }
            .navigationTitle("Files")
        }
    }
}
