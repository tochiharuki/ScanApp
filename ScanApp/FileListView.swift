import SwiftUI
import Foundation

struct FileListView: View {
    @State private var currentURL: URL
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false
    @State private var isGridView = false
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var showMoveSheet = false
    @State private var showNoSelectionAlert = false
    @State private var selectedFolderURL: URL? = nil

    private let fileManager = FileManager.default

    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue:
            currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パスバー表示
                PathBarView(currentURL: currentURL) { url in
                    if url != currentURL {
                        withAnimation {
                            currentURL = url
                        }
                    }
                }

                Divider()

                // ✅ ファイルリスト or グリッド切替
                Group {
                    if isGridView {
                        GridFileView(
                            files: filteredFiles,
                            selectedFiles: $selectedFiles,
                            isEditing: $isEditing,
                            onTap: handleTap
                        )
                    } else {
                        ListFileView(
                            files: filteredFiles,
                            selectedFiles: $selectedFiles,
                            isEditing: $isEditing,
                            onTap: handleTap,
                            deleteAction: deleteFiles
                        )
                    }
                }
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { asyncLoadFiles() }
            .onChange(of: currentURL) { _ in asyncLoadFiles() }
            .alert("No file selected", isPresented: $showNoSelectionAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert("Create New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder(named: newFolderName) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showMoveSheet) {
                NavigationStack {
                    FolderSelectionView(selectedFolderURL: $selectedFolderURL) { destination in
                        moveSelectedFiles(to: destination)
                    }
                }
            }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if isEditing {
                Button("Done") { isEditing = false; selectedFiles.removeAll() }
                Button {
                    if selectedFiles.isEmpty { showNoSelectionAlert = true }
                    else { showMoveSheet = true }
                } label: { Image(systemName: "arrow.forward") }
                Button { deleteSelectedFiles() } label: { Image(systemName: "trash") }
            } else {
                Button("Edit") { isEditing = true }
                Button { showCreateFolderAlert = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
                Button { isGridView.toggle() } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
    }

    // MARK: - Logic
    private var filteredFiles: [URL] {
        files
    }

    private func asyncLoadFiles() {
        DispatchQueue.global(qos: .userInitiated).async {
            let contents = (try? fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)) ?? []
            DispatchQueue.main.async {
                self.files = contents
            }
        }
    }

    private func handleTap(_ file: URL) {
        if isEditing {
            if selectedFiles.contains(file) { selectedFiles.remove(file) }
            else { selectedFiles.insert(file) }
        } else if file.hasDirectoryPath {
            currentURL = file
        }
    }

    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets { try? fileManager.removeItem(at: filteredFiles[index]) }
        asyncLoadFiles()
    }

    private func deleteSelectedFiles() {
        for file in selectedFiles { try? fileManager.removeItem(at: file) }
        selectedFiles.removeAll()
        asyncLoadFiles()
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        try? fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
        asyncLoadFiles()
    }

    private func moveSelectedFiles(to destination: URL) {
        for file in selectedFiles {
            let target = destination.appendingPathComponent(file.lastPathComponent)
            try? fileManager.moveItem(at: file, to: target)
        }
        selectedFiles.removeAll()
        asyncLoadFiles()
    }
}