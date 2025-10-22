import SwiftUI

struct FileListView: View {
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = [] // 複数選択用
    @State private var isEditing = false           // 編集モード切替
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var body: some View {
        NavigationView {
            List(files, id: \.self, selection: $selectedFiles) { file in
                Text(file.lastPathComponent)
                    .foregroundColor(.black)
            }
            .navigationTitle("Saved Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Delete") {
                            deleteSelectedFiles()
                        }
                        .disabled(selectedFiles.isEmpty)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                        if !isEditing {
                            selectedFiles.removeAll()
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            .onAppear(perform: loadFiles)
            .refreshable { loadFiles() }
        }
    }

    private func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            files = contents.filter { $0.pathExtension.lowercased() == "jpg" }
                .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        } catch {
            print("❌ Failed to load files:", error)
        }
    }

    private func deleteSelectedFiles() {
        for file in selectedFiles {
            do {
                try fileManager.removeItem(at: file)
            } catch {
                print("❌ Failed to delete file: \(file.lastPathComponent)")
            }
        }
        loadFiles()
        selectedFiles.removeAll()
    }
}
