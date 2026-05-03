//
//  Theme.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/23/2025.
//  Centralized visual tokens. Light + dark mode aware via system colors.
//

import SwiftUI

enum Theme {
    static let accent = Color(red: 0.18, green: 0.56, blue: 0.92)      // electric blue
    static let accentSecondary = Color(red: 0.10, green: 0.78, blue: 0.78) // teal
    static let cardBackground = Color(.secondarySystemBackground)
    static let surface = Color(.systemBackground)
    static let surfaceMuted = Color(.tertiarySystemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let separator = Color(.separator)
    static let danger = Color(red: 0.95, green: 0.30, blue: 0.35)

    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10
    static let cardShadow = Color.black.opacity(0.07)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
