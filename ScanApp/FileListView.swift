//
//  FileListView.swift
//  ScanApp
//
//  統合版 FileListView + FileListContentView
//

import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @State private var currentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パスバー
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(pathComponents(), id: \.self) { path in
                            Button(action: {
                                withAnimation {
                                    currentURL = path
                                }
                            }) {
                                Text(path.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                            if path != pathComponents().last {
                                Text("›")
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                Divider()

                // ✅ コンテンツ部分（統合）
                FileListContentView(currentURL: $currentURL)
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helper
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var current = currentURL
        while current.pathComponents.count > 1 {
            paths.insert(current, at: 0)
            current.deleteLastPathComponent()
        }
        return paths
    }
}

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
    @State private var selectedFolderURL: URL? = nil
    @State private var isLoading = false

    private let fileManager = FileManager.default

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                .searchable(text: $searchText)
                .toolbar { toolbarContent }
            }
        }
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
        if searchText.isEmpty { return files }
        return files.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
    }

    private func asyncLoadFiles() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let contents = (try? fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)) ?? []
            DispatchQueue.main.async {
                self.files = contents
                self.isLoading = false
            }
        }
    }

    private func handleTap(_ file: URL) {
        if isEditing {
            if selectedFiles.contains(file) { selectedFiles.remove(file) }
            else { selectedFiles.insert(file) }
        } else if file.hasDirectoryPath {
            withAnimation {
                currentURL = file
            }
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