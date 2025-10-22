//
//  FolderSelectionView.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/22.
//

struct FolderSelectionView: View {
    let currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var folders: [URL] = []
    private let fileManager = FileManager.default

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders, id: \.self) { folder in
                    Button {
                        onSelect(folder)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(folder.lastPathComponent)
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
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
