//
//  ScanView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

struct ScanView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)

                Text("Start scanning your documents here")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Scan")
        }
    }
}
