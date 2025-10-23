import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    // MARK: - 状態
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false
    @State private var isGridView = false
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var navigationTarget: URL? = nil
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .nameAscending
    // ✅ フォルダ移動用
    @State private var showMoveSheet = false
    @State private var selectedDestination: URL? = nil

    @State private var currentURL: URL
    private let fileManager = FileManager.default

    enum SortOption {
        case nameAscending, nameDescending, dateAscending, dateDescending
    }

    // MARK: - 初期化
    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue: currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0])
    }

    // MARK: - 本体
    var body: some View {
        NavigationStack {
            Group {
                if isGridView {
                    gridView
                } else {
                    listView
                }
            }
            .searchable(text: $searchText, prompt: "Search files")
            .navigationDestination(isPresented: Binding(
                get: { navigationTarget != nil },
                set: { if !$0 { navigationTarget = nil } }
            )) {
                if let folderURL = navigationTarget {
                    FileListView(currentURL: folderURL)
                }
            }
            .navigationTitle(currentURL.lastPathComponent)
            .toolbar {
    ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Done") {
                            withAnimation {
                                isEditing = false
                                selectedFiles.removeAll()
                            }
                        }
            
                        
            
                        Button {
                            deleteSelectedFiles()
                        } label: {
                            Image(systemName: "trash")
                        }
                        
                        Button {
                            showMoveSheet = true
 
                        } label: {
                            Image(systemName: "arrow.right.folder")
                                .foregroundColor(.black)

                        }
            
                    } else {
                        Button("Edit") {
                            withAnimation { isEditing = true }
                        }
            
                        Button {
                            showCreateFolderAlert = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
            
                        Button {
                            withAnimation { isGridView.toggle() }
                        } label: {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        }
            
                        Menu {
                            Button("Name ↑") { sortOption = .nameAscending; loadFiles() }
                            Button("Name ↓") { sortOption = .nameDescending; loadFiles() }
                            Button("Date ↑") { sortOption = .dateAscending; loadFiles() }
                            Button("Date ↓") { sortOption = .dateDescending; loadFiles() }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMoveSheet) {  // ✅ ここに出す
                FolderSelectionView(currentURL: currentURL) { destination in
                    moveSelectedFiles(to: destination)
                }
            }
            .onAppear {
                loadFiles()
            }
            
        }
    }

    // MARK: - グリッドビュー
    var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)]) {
                ForEach(filteredFiles, id: \.self) { file in
                    FileGridItem(file: file, isSelected: selectedFiles.contains(file), isEditing: isEditing)
                        .onTapGesture { handleTap(file) }
                        .onDrag {
                            NSItemProvider(contentsOf: file) ?? NSItemProvider()
                        }
                        .onDrop(of: [.fileURL],
                            delegate: DropViewDelegate(destination: file, fileManager: fileManager, refresh: { self.loadFiles() }))
                }
            }
            .padding()
        }
    }


    // MARK: - リストビュー
    var listView: some View {
        List {
            ForEach(filteredFiles, id: \.self) { file in
                HStack {
                    if isEditing {
                        Image(systemName: selectedFiles.contains(file) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedFiles.contains(file) ? .black : .gray)
                    }
                    Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                        .foregroundColor(file.hasDirectoryPath ? .black : .gray)
                        .frame(width: 24)
                    Text(file.lastPathComponent).lineLimit(1)
                }
                .contentShape(Rectangle())
                .onTapGesture { handleTap(file) }
                .background(selectedFiles.contains(file) ? Color.blue.opacity(0.1) : Color.clear)
                .onDrag {
                    let provider = NSItemProvider()
                    provider.registerDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier, visibility: .all) { completion in
                        let data = file.absoluteString.data(using: .utf8)
                        completion(data, nil)
                        return nil // Progress を返す（不要なら nil でOK）
                    }
                    return provider
                }
                .onDrop(of: [.fileURL],
                    delegate: DropViewDelegate(destination: file, fileManager: fileManager, refresh: { self.loadFiles() }))
            }
            // 🔽 ここを追加
            .onDelete(perform: deleteFiles)
        }
        .listStyle(PlainListStyle())

    }

    // MARK: - フィルター
    var filteredFiles: [URL] {
        var result = files
        if !searchText.isEmpty {
            result = result.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOption {
        case .nameAscending:
            result.sort { $0.lastPathComponent < $1.lastPathComponent }
        case .nameDescending:
            result.sort { $0.lastPathComponent > $1.lastPathComponent }
        case .dateAscending:
            result.sort {
                let dateA = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                let dateB = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                return dateA < dateB
            }
        case .dateDescending:
            result.sort {
                let dateA = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                let dateB = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                return dateA > dateB
            }
        }
        return result
    }

    // MARK: - ファイル操作
    private func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.creationDateKey])
            files = contents
        } catch { print("Failed to load files: \(error)") }
    }
    
    // MARK: - ファイル移動処理
    private func moveSelectedFiles(to destination: URL) {
        for fileURL in selectedFiles {
            let targetURL = destination.appendingPathComponent(fileURL.lastPathComponent)
            do {
                if fileManager.fileExists(atPath: targetURL.path) {
                    try fileManager.removeItem(at: targetURL)
                }
                try fileManager.moveItem(at: fileURL, to: targetURL)
            } catch {
                print("Move failed:", error)
            }
        }
        selectedFiles.removeAll()
        loadFiles()
    }


    private func deleteSelectedFiles() {
        for fileURL in selectedFiles {
            try? fileManager.removeItem(at: fileURL)
        }
        selectedFiles.removeAll()
        loadFiles()
    }
    // MARK: - スワイプ削除対応
    private func deleteFiles(at offsets: IndexSet) {
        let filesToDelete = offsets.map { filteredFiles[$0] }
        for fileURL in filesToDelete {
            try? fileManager.removeItem(at: fileURL)
        }
        loadFiles()
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        try? fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
        loadFiles()
    }

    private func handleTap(_ file: URL) {
        if isEditing {
            // 編集モード中は選択/解除
            if selectedFiles.contains(file) {
                selectedFiles.remove(file)
            } else {
                selectedFiles.insert(file)
            }
        } else {
            // 通常モードではフォルダを開く／ファイルを開く
            if file.hasDirectoryPath {
                navigationTarget = file
            } else {
                print("Open file: \(file.lastPathComponent)")
            }
        }
    }

    // ドロップ先
    struct DropViewDelegate: DropDelegate {
        let destination: URL
        let fileManager: FileManager
        // parent の代わりにリフレッシュ用クロージャを受け取る
        let refresh: () -> Void
    
        func performDrop(info: DropInfo) -> Bool {
            guard destination.hasDirectoryPath else { return false }
    
            let providers = info.itemProviders(for: [.fileURL])
            for provider in providers {
                // loadFileRepresentation を使って一時URLを取得する（より確実）
                provider.loadFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { tempURL, error in
                    guard let tempURL = tempURL else { return }
                    let targetURL = destination.appendingPathComponent(tempURL.lastPathComponent)
                    do {
                        // 既存ファイルがあれば置き換える
                        if fileManager.fileExists(atPath: targetURL.path) {
                            try fileManager.removeItem(at: targetURL)
                        }
                        try fileManager.moveItem(at: tempURL, to: targetURL)
                    } catch {
                        print("Move failed:", error)
                    }
    
                    // メインスレッドでリフレッシュを呼ぶ
                    DispatchQueue.main.async {
                        refresh()
                    }
                }
            }
            return true
        }
}

}

// MARK: - ファイルグリッドアイテム
struct FileGridItem: View {
    let file: URL
    let isSelected: Bool
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                VStack {
                    Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                        .resizable().scaledToFit().frame(width: 40, height: 40)
                        .foregroundColor(file.hasDirectoryPath ? .black : .gray)
                    Text(file.lastPathComponent).font(.caption).multilineTextAlignment(.center).lineLimit(2).frame(width: 80)
                }
                .padding(10).background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .black : .gray)
                        .padding(6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

