//
//  ContentView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

struct ContentView: View {
    @State private var scannedImages: [UIImage] = []
    @State private var showScanner: Bool = true // 自動でカメラ起動
    
    var body: some View {
        TabView {
            VStack {
                if showScanner {
                    ScanView(scannedImages: $scannedImages)
                        .onAppear {
                            // 起動時にカメラ自動表示
                            showScanner = true
                        }
                } else if scannedImages.isEmpty {
                    Text("No scanned documents yet.")
                        .foregroundColor(.black)
                        .padding()
                } else {
                    ScrollView {
                        ForEach(scannedImages, id: \.self) { img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .padding() // 余白をしっかり
                                .background(Color.white) // 画像周りも白ベース
                        }
                    }
                }
            }
            .background(Color.white)
            .tabItem {
                Label("Scan", systemImage: "camera")
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

