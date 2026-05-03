//
//  OCRViewModel.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/20/2025.

import Foundation
import UIKit
import Combine

@MainActor
final class OCRViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case success
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published var text: String = ""
    @Published private(set) var blocks: [RecognizedTextBlock] = []
    @Published private(set) var image: UIImage?
    @Published var highlightQuery: String = ""

    let documentID: UUID
    let pageID: UUID
    private let store: DocumentStoreProtocol
    private let ocrService: OCRServiceProtocol

    init(
        documentID: UUID,
        pageID: UUID,
        store: DocumentStoreProtocol,
        ocrService: OCRServiceProtocol
    ) {
        self.documentID = documentID
        self.pageID = pageID
        self.store = store
        self.ocrService = ocrService
    }

    var pageImage: UIImage? { image }

    func load() async {
        guard let doc = store.document(with: documentID),
              let page = doc.pages.first(where: { $0.id == pageID })
        else {
            state = .error("Page not found")
            return
        }
        let img = store.loadImage(for: page, inDocumentID: documentID)
        self.image = img
        if let cached = page.recognizedText, !cached.isEmpty {
            text = cached
            state = .success
            await runRecognitionForBlocks(image: img)
        } else {
            await recognize()
        }
    }

    func recognize() async {
        guard let img = image else { return }
        state = .loading
        do {
            let result = try await ocrService.recognize(image: img, languages: [])
            text = result.fullText
            blocks = result.blocks
            state = .success
            persistText(result.fullText)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func runRecognitionForBlocks(image: UIImage?) async {
        guard let img = image else { return }
        do {
            let result = try await ocrService.recognize(image: img, languages: [])
            blocks = result.blocks
        } catch {
            print("[OCRViewModel] block load failed:", error)
        }
    }

    func saveEdits() {
        persistText(text)
    }

    private func persistText(_ value: String) {
        guard let doc = store.document(with: documentID),
              var page = doc.pages.first(where: { $0.id == pageID })
        else { return }
        page.recognizedText = value
        store.updatePage(page, inDocumentID: documentID)
    }
}
