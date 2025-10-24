import SwiftUI
import Foundation

struct FileListView: View {
    @State private var currentURL: URL

    init(currentURL: URL? = nil) {
        _currentURL = State(initialValue:
            currentURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ✅ パスバー
                if !currentURL.path.isEmpty {
                    PathBarView(currentURL: currentURL) { newPath in
                        withAnimation {
                            currentURL = newPath
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: currentURL)
                }

                Divider()

                // ✅ ファイル一覧
                FileListContentView(currentURL: $currentURL)
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 念のため再ロード
                if currentURL.lastPathComponent.isEmpty {
                    currentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                }
            }
        }
    }
}