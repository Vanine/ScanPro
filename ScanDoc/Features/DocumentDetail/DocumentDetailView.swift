//
//  DocumentDetailView.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/16/2025.

import SwiftUI

struct DocumentDetailView: View {
    @StateObject var viewModel: DocumentDetailViewModel
    @EnvironmentObject private var router: AppRouter

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            Group {
                if let doc = viewModel.document {
                    if doc.pages.isEmpty {
                        EmptyStateView(
                            icon: "doc.badge.plus",
                            title: "No pages",
                            subtitle: "Add pages to this document by scanning.",
                            actionTitle: "Add page",
                            action: { router.present(.scanner(documentID: doc.id)) }
                        )
                    } else {
                        content(doc: doc)
                    }
                } else {
                    ProgressView()
                }
            }

            if case .exporting = viewModel.exportState {
                LoadingOverlay(title: "Preparing file…")
            }
        }
        .navigationTitle(viewModel.document?.name ?? "Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert(
            "Export error",
            isPresented: Binding(
                get: {
                    if case .error = viewModel.exportState { return true }
                    return false
                },
                set: { _ in }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if case .error(let m) = viewModel.exportState { Text(m) }
        }
    }

    @ViewBuilder
    private func content(doc: Document) -> some View {
        if viewModel.isReorderMode {
            reorderList(doc: doc)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    tagsSection(doc: doc)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(doc.pages.enumerated()), id: \.element.id) { idx, page in
                            Button {
                                router.push(.pageEditor(documentID: doc.id, pageID: page.id))
                            } label: {
                                pageThumb(page: page, index: idx)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    router.push(.ocrResult(documentID: doc.id, pageID: page.id))
                                } label: { Label("Recognized text", systemImage: "text.viewfinder") }
                                Button {
                                    router.push(.pageEditor(documentID: doc.id, pageID: page.id))
                                } label: { Label("Edit", systemImage: "wand.and.stars") }
                                Button(role: .destructive) {
                                    viewModel.deletePage(page)
                                } label: { Label("Delete page", systemImage: "trash") }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
    }

    private func tagsSection(doc: Document) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.textSecondary)
            FlowLayout(spacing: 6) {
                ForEach(doc.tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag).font(.caption.weight(.semibold))
                        Button {
                            viewModel.removeTag(tag)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.12))
                    .foregroundColor(Theme.accent)
                    .clipShape(Capsule())
                }
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill").font(.caption)
                    TextField("Add tag", text: $viewModel.newTagText)
                        .font(.caption.weight(.semibold))
                        .frame(width: 80)
                        .submitLabel(.done)
                        .onSubmit { viewModel.addTag() }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.cardBackground)
                .clipShape(Capsule())
            }
        }
    }

    private func reorderList(doc: Document) -> some View {
        List {
            Section {
                ForEach(Array(doc.pages.enumerated()), id: \.element.id) { idx, page in
                    HStack(spacing: 12) {
                        if let img = viewModel.image(for: page) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 44, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Text("Page \(idx + 1)")
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                    .listRowBackground(Theme.cardBackground)
                }
                .onMove { src, dst in
                    viewModel.movePages(from: src, to: dst)
                }
            } header: {
                Text("Drag the handle on the right to reorder pages")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.surface)
        .environment(\.editMode, .constant(.active))
    }

    private func pageThumb(page: ScannedPage, index: Int) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.cardBackground)
                .aspectRatio(0.72, contentMode: .fit)
            if let img = viewModel.image(for: page) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Text("\(index + 1)")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.55))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(8)
            if page.recognizedText != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "text.viewfinder")
                            .font(.caption)
                            .padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }.padding(8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.separator.opacity(0.5), lineWidth: 0.5)
        )
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                if let doc = viewModel.document {
                    Button {
                        router.present(.rename(documentID: doc.id, currentName: doc.name))
                    } label: { Label("Rename", systemImage: "pencil") }
                    Button {
                        router.present(.scanner(documentID: doc.id))
                    } label: { Label("Add pages", systemImage: "plus") }
                    Button {
                        viewModel.isReorderMode.toggle()
                    } label: {
                        Label(viewModel.isReorderMode ? "Done reordering" : "Reorder pages",
                              systemImage: "arrow.up.arrow.down")
                    }
                    Divider()
                    Button {
                        Task {
                            if let url = await viewModel.exportPDF() {
                                router.present(.sharePDF(url: url))
                            }
                        }
                    } label: { Label("Export PDF", systemImage: "doc.richtext") }
                    Button {
                        Task {
                            if let url = await viewModel.exportText() {
                                router.present(.sharePDF(url: url))
                            }
                        }
                    } label: { Label("Export text", systemImage: "doc.plaintext") }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}
