import SwiftUI
import UniformTypeIdentifiers

struct FolderSelectionView: View {
    @State var currentURL: URL
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var folders: [URL] = []
    private let fileManager = FileManager.default
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - パス階層バー
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(pathComponents(), id: \.self) { component in
                        Button {
                            navigateTo(component)
                        } label: {
                            Text(component.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(component == currentURL ? .black : .gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(component == currentURL ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }

                        if component != currentURL {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.top)

            Divider()

            // MARK: - フォルダリスト
            List(folders, id: \.self) { folder in
                Button {
                    currentURL = folder
                    loadFolders()
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.gray)
                        Text(folder.lastPathComponent)
                            .foregroundColor(.primary)
                    }
                }
                .listRowBackground(Color(.systemGray6))
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGray6))
        }
        .navigationTitle(currentURL.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray6))
        .toolbar {
            // MARK: - 戻るボタン
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(isAtRoot)
            }

            // MARK: - フォルダ作成 & 選択
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showCreateFolderAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }

                Button("Select") {
                    onSelect(currentURL)
                    dismiss()
                }
            }
        }
        .onAppear(perform: loadFolders)
        // MARK: - フォルダ作成アラート
        .alert("New Folder", isPresented: $showCreateFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                createFolder(named: newFolderName)
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - 階層パス処理
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var url = currentURL
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        while url.path.hasPrefix(documents.path) {
            paths.insert(url, at: 0)
            if url == documents { break }
            url.deleteLastPathComponent()
        }
        return paths
    }

    private func navigateTo(_ url: URL) {
        withAnimation {
            currentURL = url
            loadFolders()
        }
    }

    private func goBack() {
        let parent = currentURL.deletingLastPathComponent()
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        guard parent.path.hasPrefix(documents.path) else { return }
        withAnimation {
            currentURL = parent
            loadFolders()
        }
    }

    private var isAtRoot: Bool {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return currentURL == documents
    }

    // MARK: - フォルダ読み込み
    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
            folders = contents.filter { $0.hasDirectoryPath }
        } catch {
            print("Failed to load folders:", error)
            folders = []
        }
    }

    // MARK: - フォルダ作成
    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        do {
            try fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: false)
            loadFolders()
        } catch {
            print("Create folder failed:", error)
        }
    }
}