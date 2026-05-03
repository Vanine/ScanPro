//
//  LoadingOverlay.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/27/2025.

import SwiftUI

struct LoadingOverlay: View {
    let title: String
    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
