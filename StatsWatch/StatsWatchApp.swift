//
//  StatsWatchApp.swift
//  StatsWatch
//
//  Created by William Kuo on 2026-04-03.
//

import SwiftUI

@main
struct StatsWatchApp: App {
    @AppStorage("app_language") private var appLanguage: String = ""

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, appLanguage.isEmpty ? .current : Locale(identifier: appLanguage))
        }
    }
}
