import SwiftUI

struct FileListView: View {
    @State private var files: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isEditing = false
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    // グリッドレイアウト設定
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(files, id: \.self) { file in
                        FileItemView(
                            file: file,
                            isSelected: selectedFiles.contains(file),
                            isEditing: isEditing
                        )
                        .onTapGesture {
                            if isEditing {
                                toggleSelection(for: file)
                            } else {
                                openFile(file)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Saved Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                            if !isEditing { selectedFiles.removeAll() }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing && !selectedFiles.isEmpty {
                        Button {
                            deleteSelectedFiles()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear(perform: loadFiles)
            .refreshable {
                loadFiles()
            }
        }
    }
    
    // MARK: - ファイル操作
    private func loadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            files = contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        } catch {
            print("Failed to load files: \(error)")
        }
    }
    
    private func deleteSelectedFiles() {
        for fileURL in selectedFiles {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("Failed to delete: \(error)")
            }
        }
        selectedFiles.removeAll()
        loadFiles()
    }
    
    private func toggleSelection(for file: URL) {
        if selectedFiles.contains(file) {
            selectedFiles.remove(file)
        } else {
            selectedFiles.insert(file)
        }
    }
    
    private func openFile(_ file: URL) {
        print("Open file: \(file.lastPathComponent)")
        // 必要に応じて QuickLook などに連携可能
    }
}

struct FileItemView: View {
    let file: URL
    let isSelected: Bool
    let isEditing: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: file.hasDirectoryPath ? "folder.fill" : "doc.text.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(file.hasDirectoryPath ? .blue : .gray)
                    
                    Text(file.lastPathComponent)
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 100)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6)))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .padding(6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
