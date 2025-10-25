import SwiftUI
import Foundation

struct PathBarView: View {
    let currentURL: URL
    let onNavigate: (URL) -> Void

    private let fileManager = FileManager.default

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(pathChain(), id: \.self) { url in
                    Button(action: { onNavigate(url) }) {
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(url == currentURL ? Color(UIColor.systemGray5) : Color.clear)
                            .cornerRadius(6)
                    }
                    if url != pathChain().last {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .background(Color(UIColor.secondarySystemBackground))
    }

    // ✅ FolderSelectionViewと同じ構造のロジック
    private func pathChain() -> [URL] {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var result: [URL] = []
        var current = currentURL

        // ファイルなら親を使う
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: current.path, isDirectory: &isDirectory)
        if !isDirectory.boolValue {
            current = current.deletingLastPathComponent()
        }

        // Documents より上には行かない
        while current.path.hasPrefix(documentsURL.path) {
            result.insert(current, at: 0)
            if current == documentsURL { break }
            current.deleteLastPathComponent()
        }

        // ファイルだった場合、最後に元のURLを追加
        if !isDirectory.boolValue {
            result.append(currentURL)
        }

        return result
    }
}
