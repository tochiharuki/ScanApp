import SwiftUI
import Foundation

struct FileListView: View {
    @State private var currentURL: URL
    @State private var isLoading = false

    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue:
            currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パスバー表示
                PathBarView(currentURL: currentURL) { url in
                    if url != currentURL {
                        withAnimation {
                            currentURL = url
                        }
                    }
                }
                Divider()

                // ✅ ファイルリスト部分
                FileListContentView(currentURL: $currentURL)
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}