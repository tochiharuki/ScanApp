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
                // ✅ PathBarView（上部に表示）
                PathBarView(currentURL: currentURL) { url in
                    if url != currentURL {
                        withAnimation {
                            currentURL = url
                        }
                    }
                }

                Divider()

                // ✅ ファイル一覧ビュー
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    FileListContentView(currentURL: $currentURL)
                        .id(currentURL) // 違う階層で正しく再描画
                }
            }
            .navigationTitle(currentURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if currentURL.lastPathComponent.isEmpty {
                    currentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                }
            }
        }
    }
}