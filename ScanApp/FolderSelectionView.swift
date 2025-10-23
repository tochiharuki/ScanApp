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
                
                // MARK: - パスバー（共通コンポーネント）
                PathBarView(currentURL: currentURL) { url in
                    navigateTo(url)
                }
                
                Divider()
                
                // MARK: - フォルダ一覧
                List(folders, id: \.self) { folder in
                    Button(action: { navigateTo(folder) }) {
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
    
    // MARK: - ナビゲーション操作
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
            let contents = try FileManager.default.contentsOfDirectory(
                at: currentURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
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