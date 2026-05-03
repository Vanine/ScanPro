//
//  ScanDocTests.swift
//  ScanDocTests
//
//  Created by Vanine Ghazaryan on 02/27/2025.
//
//  Unit tests for OCRService and HomeViewModel using a mock store.
//

import XCTest
import UIKit
import Combine
@testable import ScanDoc

// MARK: - Mocks

@MainActor
final class MockDocumentStore: DocumentStoreProtocol {
    @Published var documents: [Document] = []
    var documentsPublisher: Published<[Document]>.Publisher { $documents }

    func reload() async {}

    func createDocument(name: String) -> Document {
        let d = Document(name: name)
        documents.insert(d, at: 0)
        return d
    }

    func update(_ document: Document) {
        if let i = documents.firstIndex(where: { $0.id == document.id }) {
            documents[i] = document
        } else {
            documents.append(document)
        }
    }

    func delete(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }

    func rename(_ document: Document, to newName: String) {
        var d = document; d.name = newName; update(d)
    }

    func appendPage(toDocumentID id: UUID, image: UIImage) -> ScannedPage? {
        guard var doc = document(with: id) else { return nil }
        let p = ScannedPage(imageFile: "x.jpg")
        doc.pages.append(p)
        update(doc)
        return p
    }

    func updatePage(_ page: ScannedPage, inDocumentID id: UUID) {
        guard var doc = document(with: id) else { return }
        if let i = doc.pages.firstIndex(where: { $0.id == page.id }) {
            doc.pages[i] = page; update(doc)
        }
    }

    func deletePage(_ page: ScannedPage, fromDocumentID id: UUID) {
        guard var doc = document(with: id) else { return }
        doc.pages.removeAll { $0.id == page.id }; update(doc)
    }

    func reorderPages(inDocumentID id: UUID, pages: [ScannedPage]) {
        guard var doc = document(with: id) else { return }
        doc.pages = pages; update(doc)
    }

    func loadImage(for page: ScannedPage, inDocumentID id: UUID) -> UIImage? { nil }
    func imageURL(for page: ScannedPage, inDocumentID id: UUID) -> URL {
        URL(fileURLWithPath: "/tmp/\(page.imageFile)")
    }

    func document(with id: UUID) -> Document? {
        documents.first { $0.id == id }
    }
}

final class MockOCRService: OCRServiceProtocol, @unchecked Sendable {
    var supportedLanguages: [String] { ["en-US"] }
    var stubbedResult: OCRResult = OCRResult(
        fullText: "Hello world",
        blocks: [
            RecognizedTextBlock(text: "Hello", boundingBox: CGRect(x: 0, y: 0.8, width: 0.3, height: 0.1), confidence: 0.99),
            RecognizedTextBlock(text: "world", boundingBox: CGRect(x: 0.4, y: 0.8, width: 0.3, height: 0.1), confidence: 0.95)
        ]
    )
    func recognize(image: UIImage, languages: [String]) async throws -> OCRResult {
        stubbedResult
    }
}

// MARK: - Tests

final class ScanDocTests: XCTestCase {

    @MainActor
    func test_homeViewModel_emptyState() async {
        let store = MockDocumentStore()
        let vm = HomeViewModel(store: store)
        await Task.yield()
        XCTAssertEqual(vm.state, .empty)
        XCTAssertTrue(vm.documents.isEmpty)
    }

    @MainActor
    func test_homeViewModel_loadsAndFilters() async {
        let store = MockDocumentStore()
        _ = store.createDocument(name: "Receipt")
        _ = store.createDocument(name: "Contract")
        let vm = HomeViewModel(store: store)
        await Task.yield()
        XCTAssertEqual(vm.state, .loaded)
        XCTAssertEqual(vm.documents.count, 2)

        vm.updateSearch("rec")
        XCTAssertEqual(vm.documents.count, 1)
        XCTAssertEqual(vm.documents.first?.name, "Receipt")
    }

    @MainActor
    func test_ocrViewModel_loadsCachedText() async {
        let store = MockDocumentStore()
        let doc = store.createDocument(name: "Doc")
        let page = ScannedPage(imageFile: "p.jpg", recognizedText: "Cached text")
        var d = doc; d.pages = [page]
        store.update(d)

        let vm = OCRViewModel(
            documentID: d.id,
            pageID: page.id,
            store: store,
            ocrService: MockOCRService()
        )
        await vm.load()
        XCTAssertEqual(vm.text, "Cached text")
        XCTAssertEqual(vm.state, .success)
    }

    func test_pdfService_makesValidPDF() throws {
        let svc = PDFService()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let img = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        let url = try svc.makePDF(name: "test", images: [img])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        try? FileManager.default.removeItem(at: url)
    }

    func test_pdfService_throwsOnEmpty() {
        let svc = PDFService()
        XCTAssertThrowsError(try svc.makePDF(name: "x", images: []))
    }

    func test_imageFilter_returnsImage() {
        let svc = ImageFilterService()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50))
        let img = renderer.image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
        }
        for filter in ScanFilter.allCases {
            let out = svc.apply(filter, to: img)
            XCTAssertGreaterThan(out.size.width, 0)
        }
    }
}
