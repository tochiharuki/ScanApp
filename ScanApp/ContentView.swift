//
//  ContentView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

struct ContentView: View {
    @State private var scannedImages: [UIImage] = []
    @State private var showScanner: Bool = true // 起動時に自動表示

    var body: some View {
        TabView {
            VStack {
                if scannedImages.isEmpty {
                    Text("No scanned documents yet.")
                        .foregroundColor(.black)
                        .padding()
                } else {
                    ScrollView {
                        ForEach(scannedImages, id: \.self) { img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .background(Color.white)
                        }
                    }
                }
            }
            .background(Color.white)
            .tabItem {
                Label("Scan", systemImage: "camera")
            }
            .onAppear {
                // タブが表示されたらカメラをモーダルで開く
                showScanner = true
            }
            .sheet(isPresented: $showScanner) {
                ScanView(scannedImages: $scannedImages)
            }

            FileListView()
                .tabItem {
                    Label("Files", systemImage: "folder")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .accentColor(.black)
    }
}

#Preview {
    ContentView()
}

