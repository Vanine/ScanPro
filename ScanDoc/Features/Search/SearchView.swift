//
//  SearchView.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/26/2025.

import SwiftUI

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject private var router: AppRouter
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            VStack(spacing: 0) {
                searchField
                if viewModel.query.isEmpty {
                    EmptyStateView(
                        icon: "text.magnifyingglass",
                        title: "Search inside scans",
                        subtitle: "Find any word that appears in your recognized text."
                    )
                } else if viewModel.results.isEmpty {
                    EmptyStateView(
                        icon: "questionmark.text.page",
                        title: "No matches",
                        subtitle: "Try a different keyword."
                    )
                } else {
                    List {
                        ForEach(viewModel.results) { hit in
                            Button {
                                router.push(.documentDetail(documentID: hit.document.id))
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(hit.document.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(hit.snippet)
                                        .font(.footnote)
                                        .foregroundColor(Theme.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textTertiary)
            TextField("Search documents and text", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($focused)
                .submitLabel(.search)
            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
