import SwiftUI
import Foundation

struct PathBarView: View {
    let currentURL: URL
    let onNavigate: (URL) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(pathComponents(), id: \.self) { url in
                    Button(action: {
                        onNavigate(url)
                    }) {
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }

                    if url != currentURL {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
        .background(Color(.systemGray6))
    }

    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var current = currentURL
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        while current.path != documents.deletingLastPathComponent().path {
            paths.insert(current, at: 0)
            if current == documents { break }
            current.deleteLastPathComponent()
        }
        return paths
    }
}