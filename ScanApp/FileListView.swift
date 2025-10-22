import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    // MARK: - 状態
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false   // ← 独自管理に戻す
    @State private var isGridView = false
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var navigationTarget: URL? = nil
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .nameAscending
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
                // MARK: - 操作群
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // フォルダ作成
                    Button { showCreateFolderAlert = true } label: {
                        Image(systemName: "folder.badge.plus")
                    }

                    // ビュー切替
                    Button {
                        withAnimation { isGridView.toggle() }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    }

                    // 編集中のみ削除ボタン
                    if isEditing {
                        Button {
                            deleteSelectedFiles()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }

                    // ソート
                    Menu {
                        Button("Name ↑") { sortOption = .nameAscending; loadFiles() }
                        Button("Name ↓") { sortOption = .nameDescending; loadFiles() }
                        Button("Date ↑") { sortOption = .dateAscending; loadFiles() }
                        Button("Date ↓") { sortOption = .dateDescending; loadFiles() }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }

                    // Edit / Done
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing {
                                selectedFiles.removeAll()
                            }
                        }
                    }
                }
            }
            .onAppear(perform: loadFiles)
            .refreshable { loadFiles() }
            .alert("Create New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder(named: newFolderName); newFolderName = "" }
                Button("Cancel", role: .cancel) { newFolderName = "" }
            } message: { Text("Enter a name for the new folder.") }
        }
    }

    // MARK: - グリッドビュー
    var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)]) {
                ForEach(filteredFiles, id: \.self) { file in
                    FileGridItem(
                        file: file,
                        isSelected: selectedFiles.contains(file),
                        isEditing: isEditing // ← これに変更
                    )
                    .onTapGesture { handleTap(file) }
                    .onDrag { NSItemProvider(contentsOf: file) ?? NSItemProvider() }
                    .onDrop(of: [.fileURL],
                            delegate: DropViewDelegate(destination: file, fileManager: fileManager, parent: self))
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
                .onDrag { NSItemProvider(contentsOf: file) ?? NSItemProvider() }
                .onDrop(of: [.fileURL],
                        delegate: DropViewDelegate(destination: file, fileManager: fileManager, parent: self))
            }
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
func loadFiles() { // ← private削除
    do {
        let contents = try fileManager.contentsOfDirectory(
            at: currentURL,
            includingPropertiesForKeys: [.creationDateKey]
        )
        files = contents.filter { !$0.lastPathComponent.hasPrefix(".") }
    } catch {
        print("Failed to load files: \(error)")
    }
}

private func deleteSelectedFiles() {
    for fileURL in selectedFiles {
        try? fileManager.removeItem(at: fileURL)
    }
    selectedFiles.removeAll()
    loadFiles()
}

private func createFolder(named name: String) {
    guard !name.isEmpty else { return }
    let newFolderURL = currentURL.appendingPathComponent(name)
    try? fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
    loadFiles()
}

private func handleTap(_ file: URL) {
    // 🔹 editModeが使えないため、Environmentから直接取得
    if let mode = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
        .first(where: { _ in true }) != nil {
        // 正常にeditMode使えない環境のため、状態で判断
    }

    // 代わりに、ファイル選択の判定は View側で管理済み
    if selectedFiles.contains(file) {
        selectedFiles.remove(file)
    } else {
        selectedFiles.insert(file)
    }
}


// MARK: - ドラッグ&ドロップ用 Delegate（← View の外に出した）
struct DropViewDelegate: DropDelegate {
    let destination: URL
    let fileManager: FileManager
    let parent: FileListView

    func performDrop(info: DropInfo) -> Bool {
        guard destination.hasDirectoryPath else { return false }

        let providers = info.itemProviders(for: [.fileURL])
        for provider in providers {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { tempURL, _ in
                guard let tempURL = tempURL else { return }
                let targetURL = destination.appendingPathComponent(tempURL.lastPathComponent)

                // ファイルを移動
                try? fileManager.moveItem(at: tempURL, to: targetURL)

                // 更新
                DispatchQueue.main.async {
                    parent.loadFiles()
                }
            }
        }
        return true
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
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(file.hasDirectoryPath ? .black : .gray)

                    Text(file.lastPathComponent)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 80)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

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