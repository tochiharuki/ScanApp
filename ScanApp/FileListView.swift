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
                // ✅ パスバー（FolderSelectionViewと同じロジック）
                PathBarView(currentURL: currentURL) { url in
                    withAnimation {
                        currentURL = url
                    }
                }

                Divider()

                // ✅ コンテンツ部分
                FileListContentView(currentURL: $currentURL)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
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
    @State private var sortOption: SortOption = .nameAsc

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
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if isEditing {
                            Button("Done") { isEditing = false; selectedFiles.removeAll() }
                                .font(.system(size: 17))
                            Button {
                                if selectedFiles.isEmpty { showNoSelectionAlert = true }
                                else { showMoveSheet = true }
                            } label: {
                                Image(systemName: "arrow.forward")
                                    .font(.system(size: 17))
                            }
                            Button { deleteSelectedFiles() } label: { Image(systemName: "trash") }
                                .font(.system(size: 17)) // ← ここを追加
                        } else {
                            Button("Edit") { isEditing = true }
                                .font(.system(size: 17))
                            Button { showCreateFolderAlert = true } label: {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 17))
                            }
                            Button { isGridView.toggle() } label: {
                                Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                    .font(.system(size: 17))
                            }
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(option.rawValue) { sortOption = option; sortFiles() }
                                        .font(.system(size: 17))
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 17))
                            }
                        }
                    }
                }
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
                FolderSelectionView(
                    selectedFolderURL: $selectedFolderURL,
                    currentURL: currentURL,  // ← ここで現在のディレクトリを渡す
                    onSelect: { destination in
                        moveSelectedFiles(to: destination)
                    },
                    isPresented: $showMoveSheet   // ← これを追加！
                )
                .accentColor(.black) // ここで黒に変更
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
                self.sortFiles()   // ← ここを追加！
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
    private enum SortOption: String, CaseIterable {
        case nameAsc = "Name ↑"
        case nameDesc = "Name ↓"
        case dateAsc = "Date ↑"
        case dateDesc = "Date ↓"
    }
    private func sortFiles() {
        switch sortOption {
        case .nameAsc:
            files.sort { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
        case .nameDesc:
            files.sort { $0.lastPathComponent.lowercased() > $1.lastPathComponent.lowercased() }
        case .dateAsc:
            files.sort {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return d1 < d2
            }
        case .dateDesc:
            files.sort {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return d1 > d2
            }
        }
    }



    }