import SwiftUI
import Foundation

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolderURL: URL?
    var onSelect: ((URL) -> Void)? = nil

    // 初期表示パスを外から渡せるようにする（デフォルトは Documents）
    @State private var currentURL: URL
    @State private var folders: [URL] = []
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var isLoading = false

    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    // カスタムイニシャライザ（Binding と optional currentURL）
    init(selectedFolderURL: Binding<URL?>, onSelect: ((URL) -> Void)? = nil, currentURL: URL? = nil) {
        _selectedFolderURL = selectedFolderURL
        self.onSelect = onSelect
        _currentURL = State(initialValue: currentURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0])
    }

    var body: some View {
        VStack(spacing: 0) {
            PathBarView(currentURL: currentURL) { url in
                // PathBar からのナビゲートは currentURL を更新するだけ
                if url != currentURL {
                    currentURL = url
                }
            }
            Divider()

            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // NavigationLink を使って子 FolderSelectionView（ビュー自体には NavigationStack を含めない）
                    ForEach(folders, id: \.self) { folder in
                        NavigationLink(value: folder) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.accentColor)
                                Text(folder.lastPathComponent)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.plain)
                // SwiftUI の NavigationStack と組み合わせるため、NavigationDestination をここで追加
                .navigationDestination(for: URL.self) { folder in
                    // 子は同じ View 型を使うが NavigationStack は含めない -> ネストしない
                    FolderSelectionView(selectedFolderURL: $selectedFolderURL, onSelect: onSelect, currentURL: folder)
                }
            }

            Divider()

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
            // ToolbarItem(placement: .navigationBarLeading) {
            //     Button {
            //         goBack()
            //     } label: {
            //         Label("Back", systemImage: "chevron.backward")
            //     }
            //     .disabled(currentURL.path == documentsURL.path)
            // }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear(perform: asyncLoadFolders)
        .onChange(of: currentURL) { _ in asyncLoadFolders() }
        .alert("New Folder", isPresented: $showCreateFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                createFolder(named: newFolderName)
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func goBack() {
        guard currentURL.path != documentsURL.path else { return }
        currentURL.deleteLastPathComponent()
    }

    private func asyncLoadFolders() {
        // 二重呼び出し防止
        guard !isLoading else { return }
        isLoading = true

        // キャプチャしておく（結果適用時の整合性チェック用）
        let target = currentURL

        DispatchQueue.global(qos: .userInitiated).async {
            let urls = (try? fileManager.contentsOfDirectory(at: target, includingPropertiesForKeys: [.isDirectoryKey]))?
                .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false }
                .sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() } ?? []

            DispatchQueue.main.async {
                // currentURL が変わっていたら古い結果を破棄
                if self.currentURL == target {
                    self.folders = urls
                }
                self.isLoading = false
            }
        }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newURL = currentURL.appendingPathComponent(name)
        DispatchQueue.global(qos: .userInitiated).async {
            try? fileManager.createDirectory(at: newURL, withIntermediateDirectories: true)
            DispatchQueue.main.async {
                asyncLoadFolders()
            }
        }
    }
}