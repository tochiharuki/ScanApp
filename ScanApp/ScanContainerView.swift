import SwiftUI

struct ScanContainerView: View {
    @Binding var scannedImages: [UIImage]
    @State private var showScanner = true
    @State private var scanMode: ScanMode = .single

    var body: some View {
        ZStack(alignment: .top) {
            if showScanner {
                ScanView(scannedImages: $scannedImages, mode: scanMode)
                    .edgesIgnoringSafeArea(.all)
            }

            // モード切り替えボタンを上に重ねる
            VStack {
                Picker("Scan Mode", selection: $scanMode) {
                    Text("Single").tag(ScanMode.single)
                    Text("Multiple").tag(ScanMode.multiple)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .padding(.top, 60)
                .padding(.horizontal)
                Spacer()
            }
        }
        .onAppear {
            // 少し遅らせてから自動でカメラを起動
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showScanner = true
            }
        }

        .background(Color.white)
    }
}

enum ScanMode {
    case single
    case multiple
}