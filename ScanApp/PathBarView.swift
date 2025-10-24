import SwiftUI
import Foundation

struct PathBarView: View {
    let currentURL: URL
    let onNavigate: (URL) -> Void

    // height を固定してレイアウトの安定化も図る
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(makePathComponents(), id: \.self) { url in
                    Button(action: { onNavigate(url) }) {
                        Text(url.lastPathComponent)
                            .font(.subheadline)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(url == currentURL ? Color(UIColor.systemGray4) : Color.clear)
                            .cornerRadius(6)
                    }
                    if url != makePathComponents().last {
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

    // Documents 配下のみを返す、安全な実装
    private func makePathComponents() -> [URL] {
        var components: [URL] = []
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var url = currentURL

        // safety counter で無限ループ防止
        var safety = 0
        while url.path.hasPrefix(documents.path) {
            components.insert(url, at: 0)
            if url == documents { break }
            url.deleteLastPathComponent()
            safety += 1
            if safety > 50 { break }
        }
        return components
    }
}