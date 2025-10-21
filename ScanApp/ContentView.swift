//
//  ContentView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

struct ContentView: View {
    @State private var scannedImages: [UIImage] = []
    @State private var showScanner: Bool = false
    @State private var scanMode: ScanMode = .single  // ← 追加：撮影モード
    
    var body: some View {
        TabView {
            VStack(spacing: 20) {
                Picker("Scan Mode", selection: $scanMode) {
                    Text("Single").tag(ScanMode.single)
                    Text("Multiple").tag(ScanMode.multiple)
                }
                .pickerStyle(.segmented)
                .padding()

                Button(action: {
                    showScanner = true
                }) {
                    Label("Start Scanning", systemImage: "camera")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

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
            .sheet(isPresented: $showScanner) {
                ScanView(scannedImages: $scannedImages, mode: scanMode)
            }
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

enum ScanMode {
    case single
    case multiple
}

#Preview {
    ContentView()
}