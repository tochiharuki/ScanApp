import SwiftUI

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolderURL: URL?
    
    @State private var currentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var folders: [URL] = []
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - パスバー（動的に更新）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(pathComponents(), id: \.self) { url in
                            Button(action: {
                                navigateTo(url)
                            }) {
                                Text(url.lastPathComponent)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(url == currentURL ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(5)
                            }
                            if url != pathComponents().last {
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
                
                Divider()
                
                // MARK: - フォルダ一覧
                List(folders, id: \.self) { folder in
                    Button(action: {
                        navigateTo(folder)
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text(folder.lastPathComponent)
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
                
                Divider()
                
                // MARK: - フッター操作部
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
            .onAppear(perform: loadFolders)
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
    
    // MARK: - パス構成の取得（動的）
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var current = currentURL
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        while current.path.hasPrefix(documentsURL.path) {
            paths.insert(current, at: 0)
            if current == documentsURL { break }
            current.deleteLastPathComponent()
        }
        return paths
    }

    // MARK: - ナビゲーション
    private func navigateTo(_ url: URL) {
        currentURL = url
        loadFolders()
    }

    private func goBack() {
        guard !isAtRoot else { return }
        currentURL.deleteLastPathComponent()
        loadFolders()
    }

    private var isAtRoot: Bool {
        let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return currentURL.path == root.path
    }

    // MARK: - フォルダ操作
    private func loadFolders() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey])
            folders = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            }
        } catch {
            print("Error loading folders: \(error)")
        }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: true)
            loadFolders()
        } catch {
            print("Error creating folder: \(error)")
        }
    }
}