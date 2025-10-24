import SwiftUI
import Foundation

struct FolderSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolderURL: URL?
    var onSelect: ((URL) -> Void)? = nil

    @State private var currentURL: URL
    @State private var folders: [URL] = []
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var navigationTarget: URL? = nil

    private let fileManager = FileManager.default
    private var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    init(selectedFolderURL: Binding<URL?>, onSelect: ((URL) -> Void)? = nil, currentURL: URL? = nil) {
        _selectedFolderURL = selectedFolderURL
        self.onSelect = onSelect
        _currentURL = State(initialValue: currentURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PathBarView(currentURL: currentURL) { url in currentURL = url }
                Divider()
                
                List(folders, id: \.self) { folder in
                    Button {
                        navigationTarget = folder
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill").foregroundColor(.accentColor)
                            Text(folder.lastPathComponent)
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
            .onAppear(perform: asyncLoadFolders)
            .onChange(of: currentURL) { _ in asyncLoadFolders() }
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") { createFolder(named: newFolderName); newFolderName = "" }
                Button("Cancel", role: .cancel) {}
            }
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

    private func goBack() {
        guard !isAtRoot else { return }
        currentURL.deleteLastPathComponent()
    }

    private func asyncLoadFolders() {
        DispatchQueue.global(qos: .userInitiated).async {
            let urls = (try? fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey]))?
                .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false } ?? []
            DispatchQueue.main.async { folders = urls }
        }
    }

    private func createFolder(named name: String) {
        guard !name.isEmpty else { return }
        let newURL = currentURL.appendingPathComponent(name)
        try? fileManager.createDirectory(at: newURL, withIntermediateDirectories: true)
        asyncLoadFolders()
    }
}