import SwiftUI

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolderURL: URL?
    
    @State private var currentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var folders: [URL] = []
    @State private var pathStack: [URL] = [] // ← パス階層を状態として保持
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    
    private let fileManager = FileManager.default
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - パスバー
                if !pathStack.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(pathStack, id: \.self) { url in
                                Button(action: {
                                    navigateTo(url)
                                }) {
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(url == currentURL ? Color.accentColor.opacity(0.25) : Color.clear)
                                        .cornerRadius(5)
                                }
                                
                                if url != pathStack.last {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                }
                
                Divider()
                
                // MARK: - フォルダ一覧
                List(folders, id: \.self) { folder in
                    Button {
                        navigateTo(folder)
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.accentColor)
                            Text(folder.lastPathComponent)
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
                
                Divider()
                
                // MARK: - フッター
                HStack {
                    Button("New Folder") {
                        showCreateFolderAlert = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Select") {
                        selectedFolderURL = currentURL
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: goBack) {
                        Label("Back", systemImage: "chevron.backward")
                    }
                    .disabled(isAtRoot)
                }
            }
            .onAppear {
                loadFolders()
                updatePathStack()
            }
            .onChange(of: currentURL) { _ in
                loadFolders()
                updatePathStack()
            }
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    createFolder(named: newFolderName)
                    newFolderName = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
    
    // MARK: - パススタック更新
    private func updatePathStack() {
        var stack: [URL] = []
        var url = currentURL
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        while url.path.hasPrefix(documentsURL.path) {
            stack.insert(url, at: 0)
            if url == documentsURL { break }
            url.deleteLastPathComponent()
        }
        pathStack = stack
    }

    // MARK: - ナビゲーション
    private func navigateTo(_ url: URL) {
        currentURL = url
    }

    private func goBack() {
        guard !isAtRoot else { return }
        currentURL.deleteLastPathComponent()
    }

    private var isAtRoot: Bool {
        let root = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return currentURL.path == root.path
    }

    // MARK: - フォルダ操作
    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey])
            folders = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            }.sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() })
        } catch {
            print("Error loading folders:", error)
            folders = []
        }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        do {
            try fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: true)
            loadFolders()
        } catch {
            print("Error creating folder:", error)
        }
    }
}