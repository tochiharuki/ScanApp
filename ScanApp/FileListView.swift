//
//  FileListView.swift
//  ScanApp
//
//  統合版 FileListView + FileListContentView
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit


struct FileListView: View {
    @State private var currentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var selectedFileURL: URL? = nil
    @State private var showPreview = false
    @State private var debugMessage = ""
    

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
                FileListContentView(
                    currentURL: $currentURL,
                    selectedFileURL: $selectedFileURL,
                    showPreview: $showPreview
                )
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
    @State private var sortOption: SortOption = .dateDesc  // ← デフォルトを新しい順に変更
    @State private var showRenameAlert = false
    @State private var fileToRename: URL? = nil
    @State private var newFileName = ""
    @State private var showErrorAlert = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @State private var debugMessage: String = ""
    @Binding var selectedFileURL: URL?
    @Binding var showPreview: Bool
    @State private var docController: UIDocumentInteractionController?
    @State private var docCoordinator: DocumentInteractionCoordinator?
    
    private func showErrorAlert(title: String, message: String) {
        errorAlertTitle = title
        errorAlertMessage = message
        showErrorAlert = true
    }

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
                            files: filteredFiles, // ← 修正！
                            selectedFiles: $selectedFiles,
                            isEditing: $isEditing,
                            onTap: handleTap,
                            deleteAction: { indexSet in
                                for index in indexSet {
                                    let file = filteredFiles[index]
                                    try? FileManager.default.removeItem(at: file)
                                }
                                asyncLoadFiles()
                            },
                            onRename: { file in
                                fileToRename = file
                                let name = file.hasDirectoryPath ? file.lastPathComponent : file.deletingPathExtension().lastPathComponent
                                newFileName = name
                                showRenameAlert = true
                            }
                        )
                    } else {
                        ListFileView(
                            files: filteredFiles, // ← 修正！
                            selectedFiles: $selectedFiles,
                            isEditing: $isEditing,
                            onTap: handleTap,
                            deleteAction: { indexSet in
                                for index in indexSet {
                                    let fileURL = filteredFiles[index]
                                    try? FileManager.default.removeItem(at: fileURL)
                                }
                                asyncLoadFiles()
                            },
                            onRename: { file in
                                fileToRename = file
                                let name = file.hasDirectoryPath ? file.lastPathComponent : file.deletingPathExtension().lastPathComponent
                                newFileName = name
                                showRenameAlert = true
                            }
                        )
                    }

                }
                .searchable(text: $searchText)
                .toolbar(content: toolbarContent)

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
        .alert("Rename File/Folder", isPresented: $showRenameAlert) {
            TextField("New name", text: $newFileName)
            Button("OK") { renameFile() }
            Button("Cancel", role: .cancel) {}
        }
        .alert(errorAlertTitle, isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorAlertMessage)
        }
        Text(debugMessage)
            .font(.caption)
            .foregroundColor(.gray)
            .padding(4)
        .sheet(isPresented: $showMoveSheet) {
            NavigationStack {
                FolderSelectionView(
                    selectedFolderURL: $selectedFolderURL,
                    onSelect: { destination in
                        moveSelectedFiles(to: destination)
                    },
                    currentURL: currentURL,
                    isPresented: $showMoveSheet
                )
                .accentColor(.black) // ここで黒に変更
            }
        }
        
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if isEditing {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
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
                    .font(.system(size: 17))
            }
        } else {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
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
    // MARK: - Logic
    private var filteredFiles: [URL] {
        if searchText.isEmpty { return files }
        return files.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
    }

    private func asyncLoadFiles() {
        debugMessage = "Loading files from: \(currentURL.lastPathComponent)"
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
                self.sortFiles()
                self.debugMessage = "Loaded \(contents.count) items from \(self.currentURL.lastPathComponent)"
            }
        }
    }

    private func handleTap(_ file: URL) {
        debugMessage = "Tapped: \(file.lastPathComponent)"
        if isEditing {
            if selectedFiles.contains(file) {
                selectedFiles.remove(file)
            } else {
                selectedFiles.insert(file)
            }
        } else if file.hasDirectoryPath {
            currentURL = file
        } else {
            // ✅ ファイルを直接開く（.sheetなし）
            if FileManager.default.fileExists(atPath: file.path) {
                debugMessage = "📄 Opening file: \(file.lastPathComponent)"
                
                let controller = UIDocumentInteractionController(url: file)
                let coordinator = DocumentInteractionCoordinator(onDebugMessage: { msg in
                    debugMessage = msg
                })
                controller.delegate = coordinator
                
                // 🔹 プロパティに保持してメモリ解放されないようにする
                self.docController = controller
                self.docCoordinator = coordinator
                
                UIApplication.shared.topMostViewController()?.presentPreview(for: controller)
            } else {
                debugMessage = "❌ File not found: \(file.lastPathComponent)"
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
    private func renameFile() {
        guard let file = fileToRename, !newFileName.isEmpty else { return }
    
        let ext = file.pathExtension
        let newURL = file.deletingLastPathComponent()
            .appendingPathComponent(newFileName)
            .appendingPathExtension(ext)
    
        // ⚠️ 同名ファイルがすでに存在するか確認
        if fileManager.fileExists(atPath: newURL.path) {
            showErrorAlert(title: "Rename Failed", message: "A file or folder with the same name already exists.")
            return
        }
    
        do {
            try fileManager.moveItem(at: file, to: newURL)
            asyncLoadFiles()
        } catch {
            showErrorAlert(title: "Rename Failed", message: error.localizedDescription)
        }
    
        fileToRename = nil
    }



    }
    
// MARK: - Document Interaction Helper
class DocumentInteractionCoordinator: NSObject, UIDocumentInteractionControllerDelegate {
    var onDebugMessage: ((String) -> Void)?
    init(onDebugMessage: ((String) -> Void)? = nil) {
        self.onDebugMessage = onDebugMessage
    }

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        UIApplication.shared.topMostViewController() ?? UIViewController()
    }

    func documentInteractionControllerWillBeginPreview(_ controller: UIDocumentInteractionController) {
        onDebugMessage?("👁️ Will begin preview")
    }

    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        onDebugMessage?("✅ Preview closed")
    }
}

// MARK: - Helper Extension
extension UIViewController {
    func presentPreview(for controller: UIDocumentInteractionController) {
        controller.presentPreview(animated: true)
    }
}

