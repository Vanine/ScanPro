//
//  OCRView.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/22/2025.

import SwiftUI

struct OCRView: View {
    @StateObject var viewModel: OCRViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var showingImage = true

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            VStack(spacing: 0) {
                modeToggle
                Divider()
                content
            }

            if case .loading = viewModel.state {
                LoadingOverlay(title: "Recognizing text…")
            }
        }
        .navigationTitle("Recognized text")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task { await viewModel.load() }
        .alert(
            "Recognition failed",
            isPresented: Binding(
                get: { if case .error = viewModel.state { return true } else { return false } },
                set: { _ in }
            )
        ) {
            Button("Retry") { Task { await viewModel.recognize() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            if case .error(let m) = viewModel.state { Text(m) }
        }
    }

    private var modeToggle: some View {
        Picker("Mode", selection: $showingImage) {
            Text("Image").tag(true)
            Text("Text").tag(false)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if showingImage {
            imageWithHighlights
        } else {
            textEditor
        }
    }

    private var imageWithHighlights: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.04)
                if let img = viewModel.pageImage {
                    let imageSize = img.size
                    let target = aspectFit(imageSize, into: proxy.size.insetBy(16))
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: target.width, height: target.height)
                        .overlay(
                            ForEach(highlightedBlocks(), id: \.self) { block in
                                let r = visionRect(block.boundingBox, in: target)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.accent.opacity(0.28))
                                    .frame(width: r.width, height: r.height)
                                    .position(x: r.midX, y: r.midY)
                            }
                        )
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }
        }
    }

    private func highlightedBlocks() -> [RecognizedTextBlock] {
        let q = viewModel.highlightQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return viewModel.blocks }
        return viewModel.blocks.filter { $0.text.lowercased().contains(q) }
    }

    private func aspectFit(_ size: CGSize, into target: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return target }
        let scale = min(target.width / size.width, target.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private func visionRect(_ box: CGRect, in target: CGSize) -> CGRect {
        // Vision uses bottom-left origin; flip Y.
        let x = box.minX * target.width
        let y = (1 - box.maxY) * target.height
        return CGRect(x: x, y: y, width: box.width * target.width, height: box.height * target.height)
    }

    private var textEditor: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textTertiary)
                TextField("Search inside text", text: $viewModel.highlightQuery)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            TextEditor(text: $viewModel.text)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
                .background(Theme.surface)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                viewModel.saveEdits()
                UIPasteboard.general.string = viewModel.text
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(viewModel.text.isEmpty)

            Button {
                viewModel.saveEdits()
                router.present(.shareText(text: viewModel.text))
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(viewModel.text.isEmpty)
        }
    }
}

private extension CGSize {
    func insetBy(_ inset: CGFloat) -> CGSize {
        CGSize(width: max(0, width - inset * 2), height: max(0, height - inset * 2))
    }
}
