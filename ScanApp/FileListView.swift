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
                                    .foregroundColor(path == currentURL ? .primary : .blue)
                                    .lineLimit(1)
                            }

                            // ➡ 区切り記号
                            if path != pathComponents().last {
                                Text("›")
                                    .foregroundColor(.gray)
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
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        var current = currentURL

        // 📁 ファイルの場合は親ディレクトリを基準にする
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: current.path, isDirectory: &isDirectory)
        if !isDirectory.boolValue {
            current = current.deletingLastPathComponent()
        }

        // 📁 Documentsより上に行かないようにしつつ、上層を追加
        while true {
            paths.insert(current, at: 0)
            if current == documentsURL { break }

            let parent = current.deletingLastPathComponent()
            if !parent.path.hasPrefix(documentsURL.path) { break } // Documentsより上なら終了
            current = parent
        }

        // 📄 最後にファイル自身を追加（もしファイルを開いているなら）
        FileManager.default.fileExists(atPath: currentURL.path, isDirectory: &isDirectory)
        if !isDirectory.boolValue {
            paths.append(currentURL)
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
    @State private var isReloading = false   // ← body の外に書く

    private let fileManager = FileManager.default

    var body: some View {   // ← 正しく body を宣言
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
        .onChange(of: currentURL) { _ in
            guard !isReloading else { return }
            isReloading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                asyncLoadFiles()
                isReloading = false
            }
        }
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
        isReloading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let contents = (try? fileManager.contentsOfDirectory(
                at: self.currentURL,
                includingPropertiesForKeys: [.isDirectoryKey, .creationDateKey]
            )) ?? []
    
            DispatchQueue.main.async {
                self.files = contents
                self.isLoading = false
                self.isReloading = false
            }
        }
    }

    private func handleTap(_ file: URL) {
        if isEditing {
            if selectedFiles.contains(file) { selectedFiles.remove(file) }
            else { selectedFiles.insert(file) }
        } else if file.hasDirectoryPath {
            currentURL = file // まずはアニメーションなしで
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