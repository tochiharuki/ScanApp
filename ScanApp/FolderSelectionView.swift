import SwiftUI  
import UniformTypeIdentifiers


struct FolderSelectionView: View {
    let currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var folders: [URL] = []
    private let fileManager = FileManager.default
    @State private var selectedFolder: URL?

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders, id: \.self) { folder in
                    NavigationLink(destination: FolderSelectionView(currentURL: folder, onSelect: onSelect)) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(folder.lastPathComponent)
                        }
                    }
                }
            }
            .navigationTitle(currentURL.lastPathComponent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select") {
                        onSelect(currentURL)
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadFolders)
        }
    }

    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
            folders = contents.filter { $0.hasDirectoryPath }
        } catch {
            print("Failed to load folders:", error)
        }
    }
}