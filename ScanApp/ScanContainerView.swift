import SwiftUI

struct ContentView: View {
    @State private var scannedImages: [UIImage] = []

    var body: some View {
        TabView {
            ScanView(scannedImages: $scannedImages)
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