import SwiftUI
import Foundation

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolderURL: URL?          // 選択されたフォルダ

    // 選択時に呼ぶクロージャ
    var onSelect: ((URL) -> Void)? = nil

    @State private var currentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var folders: [URL] = []
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ 常に固定されるパスバー
                PathBarView(currentURL: currentURL) { url in
                    currentURL = url
                }
                .padding(.vertical, 4)
                .background(Color(uiColor: .systemGray6))
                .zIndex(1)

                Divider()

                // ✅ フォルダ一覧はスクロール可能
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(folders, id: \.self) { folder in
                            Button {
                                currentURL = folder
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.accentColor)
                                    Text(folder.lastPathComponent)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                Divider()

                // ✅ フッター固定
                HStack {
                    Button("New Folder") { showCreateFolderAlert = true }
                        .buttonStyle(.bordered)

                    Spacer()

                    Button("Select") {
                        selectedFolderURL = currentURL
                        onSelect?(currentURL)
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
                    Button { goBack() } label: { Label("Back", systemImage: "chevron.backward") }
                        .disabled(isAtRoot)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { loadFolders() }
            .onChange(of: currentURL) { _ in loadFolders() }
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder(named: newFolderName); newFolderName = "" }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - ヘルパー
    private var isAtRoot: Bool { currentURL.path == documentsURL.path }

    private func goBack() { if !isAtRoot { currentURL.deleteLastPathComponent() } }

    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey])
            folders = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false }
        } catch {
            folders = []
            print("Error loading folders:", error)
        }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        try? fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: true)
        loadFolders()
    }
}