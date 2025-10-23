import SwiftUI
import UniformTypeIdentifiers

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let currentURL: URL
    let onSelect: (URL) -> Void

    @State private var folders: [URL] = []
    @State private var selectedFolder: URL?
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""

    private let fileManager = FileManager.default

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // パスバー
                PathBarView(currentURL: currentURL) { newPath in
                    selectedFolder = nil
                    loadFolders(at: newPath)
                }

                // フォルダ一覧
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
            }
            .navigationTitle(currentURL.lastPathComponent)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("New Folder") {
                        showCreateFolderAlert = true
                    }
                    Button("Select") {
                        onSelect(currentURL)
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFolders(at: currentURL)
            }
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Helper

    private func loadFolders(at url: URL) {
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            folders = contents.filter { $0.hasDirectoryPath }
        } catch {
            print("Failed to load folders:", error)
        }
    }

    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(newFolderName)
        do {
            try fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: true)
            loadFolders(at: currentURL)
            newFolderName = ""
        } catch {
            print("Failed to create folder:", error)
        }
    }
}