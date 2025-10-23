import SwiftUI
import Foundation

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolderURL: URL?
    var onSelect: ((URL) -> Void)? = nil

    @State private var currentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var folders: [URL] = []

    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""

    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    @State private var navigationTarget: URL? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PathBarView(currentURL: currentURL) { url in
                    currentURL = url
                }
                Divider()
                
                List(folders, id: \.self) { folder in
                    Button {
                        navigationTarget = folder
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill").foregroundColor(.accentColor)
                            Text(folder.lastPathComponent).foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
                
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { goBack() } label: { Label("Back", systemImage: "chevron.backward") }
                        .disabled(isAtRoot)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadFolders)
            .onChange(of: currentURL) { _ in loadFolders() }
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder(named: newFolderName); newFolderName = "" }
                Button("Cancel", role: .cancel) {}
            }
            // ✅ NavigationStack で深い階層に遷移
            .navigationDestination(isPresented: Binding(
                get: { navigationTarget != nil },
                set: { if !$0 { navigationTarget = nil } }
            )) {
                if let folder = navigationTarget {
                    FolderSelectionView(selectedFolderURL: $selectedFolderURL, onSelect: onSelect, currentURL: folder)
                }
            }
        }
    }

    private var isAtRoot: Bool { currentURL.path == documentsURL.path }

    private func goBack() { if !isAtRoot { currentURL.deleteLastPathComponent() } }

    private func loadFolders() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey])
            folders = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false }
        } catch { folders = []; print("Error loading folders:", error) }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newFolderURL = currentURL.appendingPathComponent(name)
        try? fileManager.createDirectory(at: newFolderURL, withIntermediateDirectories: true)
        loadFolders()
    }
}