import SwiftUI

struct FileListView: View {
    @State private var files: [URL] = []
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var body: some View {
        NavigationView {
            List(files, id: \.self) { file in
                Text(file.lastPathComponent)
                    .foregroundColor(.black)
            }
            .navigationTitle("Saved Files")
            .onAppear(perform: loadFiles)
            .refreshable {
                loadFiles()
            }
            .background(Color.white)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            loadFiles()
        }
    }

    private func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            files = contents.filter { $0.pathExtension.lowercased() == "jpg" }
                .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        } catch {
            print("❌ Failed to load files:", error)
        }
    }
}