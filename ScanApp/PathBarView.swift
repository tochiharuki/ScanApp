import SwiftUI

struct PathBarView: View {
    let currentURL: URL
    let onNavigate: (URL) -> Void
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(pathComponents(), id: \.self) { url in
                    Button {
                        onNavigate(url)
                    } label: {
                        Text(url.lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(url == currentURL ? .primary : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(url == currentURL ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    if url != pathComponents().last {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .frame(minHeight: 40) // ✅ 高さを保証
    }
    
    private func pathComponents() -> [URL] {
        var paths: [URL] = []
        var url = currentURL
        while url.path.hasPrefix(documentsURL.path) {
            paths.insert(url, at: 0)
            if url == documentsURL { break }
            url.deleteLastPathComponent()
        }
        return paths
    }
}