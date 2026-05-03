//
//  ScanDocApp.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/05/2025.
//
//  Production-quality document scanner with OCR & PDF export.
//  MVVM + Router + DI architecture.
//

import SwiftUI

@main
struct ScanDocApp: App {
    /// Root dependency container. Single source of truth for services.
    @StateObject private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .preferredColorScheme(nil) // respects system light/dark
                .tint(Theme.accent)
        }
    }
}
