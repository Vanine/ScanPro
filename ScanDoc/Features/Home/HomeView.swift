//
//  HomeView.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/06/2025.

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.surface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if !viewModel.recents.isEmpty {
                        recentsSection
                    }

                    if !viewModel.allTags.isEmpty {
                        tagBar
                    }

                    documentsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .refreshable { await viewModel.refresh() }

            scanFab
                .padding(.trailing, 22)
                .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "doc.viewfinder.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.heroGradient)
            }
            ToolbarItem(placement: .principal) {
                Text("ScanDoc")
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.search)
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.updateSearch($0) }
            ),
            prompt: "Search documents & text"
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            Text("Your documents")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently scanned")
                    .font(.headline)
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.recents) { doc in
                        Button {
                            router.push(.documentDetail(documentID: doc.id))
                        } label: {
                            RecentCard(
                                document: doc,
                                thumbnail: viewModel.thumbnail(for: doc)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tagPill("All", isSelected: viewModel.selectedTag == nil) {
                    viewModel.selectTag(nil)
                }
                ForEach(viewModel.allTags, id: \.self) { tag in
                    tagPill(tag, isSelected: viewModel.selectedTag == tag) {
                        viewModel.selectTag(viewModel.selectedTag == tag ? nil : tag)
                    }
                }
            }
        }
    }

    private func tagPill(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            Theme.heroGradient
                        } else {
                            Theme.cardBackground
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : Theme.textPrimary)
                .clipShape(Capsule())
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All documents")
                .font(.headline)

            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 80)
            case .empty:
                EmptyStateView(
                    icon: "doc.viewfinder",
                    title: "No documents yet",
                    subtitle: "Tap the scan button below to capture your first page.",
                    actionTitle: "Start scanning",
                    action: { router.present(.scanner(documentID: nil)) }
                )
                .frame(minHeight: 320)
            case .loaded:
                if viewModel.documents.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Nothing matches",
                        subtitle: "Try another keyword or clear the filter."
                    )
                    .frame(minHeight: 240)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.documents) { doc in
                            Button {
                                router.push(.documentDetail(documentID: doc.id))
                            } label: {
                                DocumentRow(
                                    document: doc,
                                    thumbnail: viewModel.thumbnail(for: doc)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    router.present(.rename(documentID: doc.id, currentName: doc.name))
                                } label: { Label("Rename", systemImage: "pencil") }
                                Button(role: .destructive) {
                                    viewModel.delete(doc)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.delete(doc)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
        }
    }

    private var scanFab: some View {
        Button {
            router.present(.scanner(documentID: nil))
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: Theme.accent.opacity(0.45), radius: 18, x: 0, y: 10)
                Image(systemName: "doc.viewfinder.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel("New scan")
    }
}

private struct RecentCard: View {
    let document: Document
    let thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surfaceMuted)
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Theme.heroGradient)
                }
            }
            .frame(width: 130, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.separator.opacity(0.4), lineWidth: 0.5)
            )

            Text(document.name)
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
            Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 130)
    }
}
