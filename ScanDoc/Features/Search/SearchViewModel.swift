//
//  SearchViewModel.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/24/2025.

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    struct Hit: Identifiable, Hashable {
        let id = UUID()
        let document: Document
        let snippet: String
    }

    @Published var query: String = ""
    @Published private(set) var results: [Hit] = []

    private let store: DocumentStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(store: DocumentStoreProtocol) {
        self.store = store
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(180), scheduler: RunLoop.main)
            .sink { [weak self] q in self?.runSearch(q) }
            .store(in: &cancellables)
    }

    private func runSearch(_ q: String) {
        let trimmed = q.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        results = store.documents.compactMap { doc in
            let nameMatch = doc.name.lowercased().contains(trimmed)
            let textMatch = doc.combinedText.lowercased().contains(trimmed)
            guard nameMatch || textMatch else { return nil }
            let snippet = makeSnippet(text: doc.combinedText, query: trimmed) ?? doc.name
            return Hit(document: doc, snippet: snippet)
        }
    }

    private func makeSnippet(text: String, query: String) -> String? {
        let lowered = text.lowercased()
        guard let range = lowered.range(of: query) else { return nil }
        let start = lowered.index(range.lowerBound, offsetBy: -40, limitedBy: lowered.startIndex) ?? lowered.startIndex
        let end = lowered.index(range.upperBound, offsetBy: 40, limitedBy: lowered.endIndex) ?? lowered.endIndex
        let snippet = String(text[start..<end])
            .replacingOccurrences(of: "\n", with: " ")
        return "…\(snippet)…"
    }
}
