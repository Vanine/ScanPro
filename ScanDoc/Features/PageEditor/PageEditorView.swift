//
//  PageEditorView.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/12/2025.

import SwiftUI

struct PageEditorView: View {
    @StateObject var viewModel: PageEditorViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                imageArea
                controls
            }

            if case .processing = viewModel.state {
                LoadingOverlay(title: "Applying filter…")
            }
        }
        .navigationTitle("Edit page")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.save()
                    router.pop()
                }
                .font(.body.weight(.semibold))
            }
        }
        .onAppear { viewModel.load() }
    }

    private var imageArea: some View {
        GeometryReader { proxy in
            Group {
                if let img = viewModel.displayedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ProgressView().tint(.white)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(ScanFilter.allCases) { filter in
                    Button {
                        Task { await viewModel.apply(filter) }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: icon(for: filter))
                                .font(.system(size: 18, weight: .semibold))
                            Text(filter.label)
                                .font(.caption.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.selectedFilter == filter
                                ? AnyView(Theme.heroGradient)
                                : AnyView(Color.white.opacity(0.08))
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            HStack {
                Button {
                    viewModel.rotate()
                } label: {
                    Label("Rotate", systemImage: "rotate.right")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Spacer()
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
    }

    private func icon(for filter: ScanFilter) -> String {
        switch filter {
        case .original: return "photo"
        case .enhanced: return "sparkles"
        case .blackAndWhite: return "circle.lefthalf.filled"
        case .grayscale: return "camera.filters"
        }
    }
}
