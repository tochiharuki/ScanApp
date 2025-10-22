import SwiftUI

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isFolder: Bool
    var image: UIImage? = nil
    var children: [FileItem]? = nil
}


struct FileListView: View {
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false
    @State private var isGridView = false   // ← アイコン表示切替
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var navigationTarget: URL? = nil


    // ✅ 「今見ているフォルダのURL」を保持（← Stateで可変）
    @State private var currentURL: URL
    private let fileManager = FileManager.default

    // ✅ 初期化時にどのフォルダを表示するか指定
    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue: currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0])
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isGridView {
                    // アイコン表示
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)]) {
                            ForEach(files, id: \.self) { file in
                                FileGridItem(
                                    file: file,
                                    isSelected: selectedFiles.contains(file),
                                    isEditing: isEditing
                                )
                                .onTapGesture {
                                    if isEditing {
                                        toggleSelection(for: file)
                                    } else {
                                        openFile(file)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // リスト表示
                    List(selection: $selectedFiles) {
                        ForEach(files, id: \.self) { file in
                            HStack {
                                if isEditing {
                                    Image(systemName: selectedFiles.contains(file) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedFiles.contains(file) ? .blue : .gray)
                                }
                                Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                                    .foregroundColor(file.hasDirectoryPath ? .blue : .gray)
                                    .frame(width: 24)
                                Text(file.lastPathComponent)
                                    .lineLimit(1)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isEditing {
                                    toggleSelection(for: file)
                                } else {
                                    openFile(file)
                                }
                            }
                            .background(selectedFiles.contains(file) ? Color.blue.opacity(0.1) : Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
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
                    // 右側にまとめる
                    // 🟦 フォルダ作成ボタン追加
                    Button {
                        showCreateFolderAlert = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    Button {
                        withAnimation {
                            isGridView.toggle()
                        }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    }
                    
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing { selectedFiles.removeAll() }
                        }
                    }
                    
                    if isEditing && !selectedFiles.isEmpty {
                        Button {
                            deleteSelectedFiles()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear(perform: loadFiles)
            .refreshable {
                loadFiles()
            }
            .alert("Create New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    createFolder(named: newFolderName)
                    newFolderName = ""
                }
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
            } message: {
                Text("Enter a name for the new folder.")
            }

        }
    }
    
    // MARK: - ファイル操作
    private func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
            files = contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        } catch {
            print("Failed to load files: \(error)")
        }
    }
    
    private func deleteSelectedFiles() {
        for fileURL in selectedFiles {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Failed to delete: \(error)")
            }
        }
        selectedFiles.removeAll()
        loadFiles()
    }
    
    private func toggleSelection(for file: URL) {
        if selectedFiles.contains(file) {
            selectedFiles.remove(file)
        } else {
            selectedFiles.insert(file)
        }
    }
    
    private func openFile(_ file: URL) {
        if file.hasDirectoryPath {
            navigationTarget = file  // ✅ ここで遷移先をセット
        } else {
            print("Open file: \(file.lastPathComponent)")
            // ここで QuickLook やシェア機能を呼び出すことも可能
        }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)

        do {
            try fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
            loadFiles()
        } catch {
            print("Failed to create folder: \(error)")
        }
    }

}

struct FileGridItem: View {
    let file: URL
    let isSelected: Bool
    let isEditing: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                VStack {
                    if file.pathExtension.lowercased() == "jpg" || file.pathExtension.lowercased() == "png" {
                        // 🖼️ サムネイル表示
                        if let uiImage = UIImage(contentsOfFile: file.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        }
                    } else {
                        // 通常アイコン
                        Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(file.hasDirectoryPath ? .blue : .gray)
                    }
                    
                    Text(file.lastPathComponent)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 80)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

                // 編集モードのラジオボタン
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .padding(6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

