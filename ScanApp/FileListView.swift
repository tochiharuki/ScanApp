import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false
    @State private var isGridView = false
    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var navigationTarget: URL? = nil
    @State private var showMoveSheet = false
    @State private var showNoSelectionAlert = false
    @State private var currentURL: URL
    @State private var searchText = ""
    @State private var sortOption: SortOption = .nameAscending

    private let fileManager = FileManager.default

    enum SortOption {
        case nameAscending, nameDescending, dateAscending, dateDescending
    }

    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue:
            currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // ✅ パスバーを上に追加
            PathBarView(currentURL: currentURL) { newPath in
                navigationTarget = newPath
            }

            Divider()

            NavigationStack {
                Group {
                    if isGridView {
                        gridView
                    } else {
                        listView
                    }
                }
                .searchable(text: $searchText)
                .navigationDestination(isPresented: Binding(
                    get: { navigationTarget != nil },
                    set: { if !$0 { navigationTarget = nil } }
                )) {
                    if let folderURL = navigationTarget {
                        FileListView(currentURL: folderURL)
                    }
                }
                .navigationTitle(currentURL.lastPathComponent)
                .toolbar { toolbarContent }
                .onAppear { loadFiles() }
                .alert("No file selected", isPresented: $showNoSelectionAlert) {
                    Button("OK", role: .cancel) {}
                }
                .alert("Create New Folder", isPresented: $showCreateFolderAlert) {
                    TextField("Folder name", text: $newFolderName)
                    Button("Create") { createFolder(named: newFolderName) }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Enter a name for the new folder.")
                }
                .sheet(isPresented: $showMoveSheet) {
                    FolderSelectionView(currentURL: currentURL) { destination in
                        moveSelectedFiles(to: destination)
                    }
                }
            }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if isEditing {
                Button("Done") {
                    isEditing = false
                    selectedFiles.removeAll()
                }

                Button {
                    if selectedFiles.isEmpty {
                        showNoSelectionAlert = true
                    } else {
                        showMoveSheet = true
                    }
                } label: { Image(systemName: "arrow.forward") }

                Button {
                    deleteSelectedFiles()
                } label: { Image(systemName: "trash") }

            } else {
                Button("Edit") { isEditing = true }
                Button { showCreateFolderAlert = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
                Button { isGridView.toggle() } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
    }

    // MARK: - Views
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(filteredFiles, id: \.self) { file in
                    FileGridItem(file: file, isSelected: selectedFiles.contains(file), isEditing: isEditing)
                        .onTapGesture { handleTap(file) }
                }
            }
            .padding()
        }
    }

    private var listView: some View {
        List {
            ForEach(filteredFiles, id: \.self) { file in
                HStack {
                    if isEditing {
                        Image(systemName: selectedFiles.contains(file) ? "checkmark.circle.fill" : "circle")
                    }
                    Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                    Text(file.lastPathComponent)
                }
                .onTapGesture { handleTap(file) }
            }
            .onDelete(perform: deleteFiles)
        }
        .listStyle(.plain)
    }

    // MARK: - Logic
    private var filteredFiles: [URL] {
        var result = files
        if !searchText.isEmpty {
            result = result.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private func loadFiles() {
        do {
            files = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil)
        } catch { print(error) }
    }

    private func handleTap(_ file: URL) {
        if isEditing {
            if selectedFiles.contains(file) { selectedFiles.remove(file) }
            else { selectedFiles.insert(file) }
        } else if file.hasDirectoryPath {
            navigationTarget = file
        }
    }

    private func deleteFiles(at offsets: IndexSet) {
        for index in offsets {
            try? fileManager.removeItem(at: filteredFiles[index])
        }
        loadFiles()
    }

    private func deleteSelectedFiles() {
        for file in selectedFiles { try? fileManager.removeItem(at: file) }
        selectedFiles.removeAll()
        loadFiles()
    }

    private func moveSelectedFiles(to destination: URL) {
        for file in selectedFiles {
            let target = destination.appendingPathComponent(file.lastPathComponent)
            try? fileManager.moveItem(at: file, to: target)
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
}