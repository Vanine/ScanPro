//
//  DocumentDetailViewModel.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/14/2025.

import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
final class DocumentDetailViewModel: ObservableObject {
    enum ExportState: Equatable {
        case idle
        case exporting
        case error(String)
    }

    @Published private(set) var document: Document?
    @Published private(set) var exportState: ExportState = .idle
    @Published var isReorderMode: Bool = false
    @Published var newTagText: String = ""

    let documentID: UUID
    private let store: DocumentStoreProtocol
    private let pdfService: PDFServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        documentID: UUID,
        store: DocumentStoreProtocol,
        pdfService: PDFServiceProtocol
    ) {
        self.documentID = documentID
        self.store = store
        self.pdfService = pdfService
        bind()
    }

    private func bind() {
        store.documentsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] docs in
                guard let self else { return }
                self.document = docs.first { $0.id == self.documentID }
            }
            .store(in: &cancellables)
        document = store.document(with: documentID)
    }

    func image(for page: ScannedPage) -> UIImage? {
        store.loadImage(for: page, inDocumentID: documentID)
    }

    func deletePage(_ page: ScannedPage) {
        store.deletePage(page, fromDocumentID: documentID)
    }

    func movePages(from source: IndexSet, to destination: Int) {
        guard var doc = document else { return }
        doc.pages.move(fromOffsets: source, toOffset: destination)
        store.reorderPages(inDocumentID: documentID, pages: doc.pages)
    }

    func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var doc = document else { return }
        if !doc.tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            doc.tags.append(trimmed)
            store.update(doc)
        }
        newTagText = ""
    }

    func removeTag(_ tag: String) {
        guard var doc = document else { return }
        doc.tags.removeAll { $0 == tag }
        store.update(doc)
    }

    // MARK: - Exports

    func exportPDF() async -> URL? {
        guard let doc = document, !doc.pages.isEmpty else { return nil }
        exportState = .exporting
        let images: [UIImage] = doc.pages.compactMap { store.loadImage(for: $0, inDocumentID: documentID) }
        do {
            let url = try pdfService.makePDF(name: doc.name, images: images)
            exportState = .idle
            return url
        } catch {
            exportState = .error(error.localizedDescription)
            return nil
        }
    }

    func exportText() async -> URL? {
        guard let doc = document else { return nil }
        let text = doc.combinedText
        guard !text.isEmpty else {
            exportState = .error("No recognized text to export.")
            return nil
        }
        exportState = .exporting
        do {
            let url = try pdfService.makeTextFile(name: doc.name, text: text)
            exportState = .idle
            return url
        } catch {
            exportState = .error(error.localizedDescription)
            return nil
        }
    }
}
