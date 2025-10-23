//
//  FileListContentView.swift
//  ScanApp
//

import SwiftUI
import UniformTypeIdentifiers

struct FileListContentView: View {
    @Binding var currentURL: URL
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false
    @State private var isGridView = false
    @State private var searchText = ""
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var showMoveSheet = false
    @State private var showNoSelectionAlert = false

    private let fileManager = FileManager.default

    var body: some View {
        VStack(spacing: 0) {
            // PathBar
            PathBarView(currentURL: currentURL) { newPath in
                currentURL = newPath
            }
            Divider()

            // ファイル表示
            if isGridView {
                GridFileView(files: filteredFiles, selectedFiles: $selectedFiles, isEditing: $isEditing) { file in
                    handleTap(file)
                }
            } else {
                ListFileView(files: filteredFiles, selectedFiles: $selectedFiles, isEditing: $isEditing) { file in
                    handleTap(file)
                } deleteAction: { offsets in
                    deleteFiles(at: offsets)
                }
            }
        }
        .searchable(text: $searchText)
        .toolbar { toolbarContent }
        .onAppear { loadFiles() }
        .alert("No file selected", isPresented: $showNoSelectionAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Create New Folder", isPresented: $showCreateFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") { createFolder(named: newFolderName) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Enter a name for the new folder.") }
        .sheet(isPresented: $showMoveSheet) {
            FolderSelectionView(selectedFolderURL: $selectedFiles.first) { destination in
                moveSelectedFiles(to: destination)
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
        if searchText.isEmpty { return files }
        return files.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
    }

    private func loadFiles() {
        do {
            files = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
        } catch {
            print("Failed to load files:", error)
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
        loadFiles()
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        try? fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
        loadFiles()
    }

    private func moveSelectedFiles(to destination: URL) {
        for file in selectedFiles {
            let target = destination.appendingPathComponent(file.lastPathComponent)
            try? fileManager.moveItem(at: file, to: target)
        }
        selectedFiles.removeAll()
        loadFiles()
    }
}