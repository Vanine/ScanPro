//
//  HomeViewModel.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/04/2025.

import Foundation
import Combine
import UIKit

@MainActor
final class HomeViewModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case empty
        case loaded
    }

    @Published private(set) var documents: [Document] = []
    @Published private(set) var state: ViewState = .loading
    @Published var searchQuery: String = ""
    @Published var selectedTag: String? = nil

    private let store: DocumentStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(store: DocumentStoreProtocol) {
        self.store = store
        bind()
    }

    private func bind() {
        store.documentsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] docs in
                guard let self else { return }
                self.applyDocuments(docs)
            }
            .store(in: &cancellables)
    }

    private func applyDocuments(_ docs: [Document]) {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        var filtered = docs
        if !q.isEmpty {
            filtered = filtered.filter {
                $0.name.lowercased().contains(q) ||
                $0.combinedText.lowercased().contains(q) ||
                $0.tags.contains { $0.lowercased().contains(q) }
            }
        }
        if let tag = selectedTag {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        documents = filtered
        if docs.isEmpty {
            state = .empty
        } else {
            state = .loaded
        }
    }

    func refresh() async {
        state = .loading
        await store.reload()
    }

    func updateSearch(_ q: String) {
        searchQuery = q
        applyDocuments(store.documents)
    }

    func selectTag(_ tag: String?) {
        selectedTag = tag
        applyDocuments(store.documents)
    }

    func delete(_ document: Document) {
        store.delete(document)
    }

    func thumbnail(for document: Document) -> UIImage? {
        guard let first = document.pages.first else { return nil }
        return store.loadImage(for: first, inDocumentID: document.id)
    }

    var allTags: [String] {
        let set = Set(store.documents.flatMap { $0.tags })
        return Array(set).sorted()
    }

    var recents: [Document] {
        Array(store.documents.prefix(5))
    }
}
