//
//  ScanAppApp.swift
//  ScanApp
//
//  Created by Tochishita Haruki on 2025/10/21.
//

import SwiftUI

@main
struct ScanAppApp: App {
    init() {
        // アプリ全体のナビゲーションバーやタブの色を設定したい場合
        UINavigationBar.appearance().backgroundColor = .white
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black]
        
        UITabBar.appearance().backgroundColor = .white
        UITabBar.appearance().tintColor = .black  // 選択中のアイコン色
        UITabBar.appearance().unselectedItemTintColor = .gray
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(.black) // ボタンなどのアクセントカラー
                .preferredColorScheme(.light) // 常にライトモード
        }
    }
}