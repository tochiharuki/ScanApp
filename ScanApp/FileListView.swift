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
                // ✅ パスバーを上部に表示
                PathBarView(currentURL: currentURL) { newPath in
                    currentURL = newPath
                }
                
                Divider()
                
                // ✅ ファイル一覧（リスト/グリッド切替・検索・操作）
                FileListContentView(currentURL: $currentURL)
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}