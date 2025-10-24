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
                // ✅ 常にパスバーを表示
                PathBarView(currentURL: currentURL) { url in
                    if url != currentURL {
                        withAnimation {
                            currentURL = url
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
                .overlay(Divider(), alignment: .bottom)

                // ✅ コンテンツ部分
                FileListContentView(currentURL: $currentURL)
            }
            // タイトルは空にしてツールバーに表示されないようにする
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar) // ← ツールバーを完全に非表示
        }
    }
}