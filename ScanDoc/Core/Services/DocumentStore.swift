//
//  DocumentStore.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/15/2025.
//  Persistence on top of FileManager. Each document is a folder containing
//  page images and a `document.json` manifest. Offline & deterministic.
//

import Foundation
import UIKit
import Combine

@MainActor
protocol DocumentStoreProtocol: AnyObject {
    var documentsPublisher: Published<[Document]>.Publisher { get }
    var documents: [Document] { get }

    func reload() async
    func createDocument(name: String) -> Document
    func update(_ document: Document)
    func delete(_ document: Document)
    func rename(_ document: Document, to newName: String)

    @discardableResult
    func appendPage(toDocumentID id: UUID, image: UIImage) -> ScannedPage?
    func updatePage(_ page: ScannedPage, inDocumentID id: UUID)
    func deletePage(_ page: ScannedPage, fromDocumentID id: UUID)
    func reorderPages(inDocumentID id: UUID, pages: [ScannedPage])

    func loadImage(for page: ScannedPage, inDocumentID id: UUID) -> UIImage?
    func imageURL(for page: ScannedPage, inDocumentID id: UUID) -> URL
    func document(with id: UUID) -> Document?
}

@MainActor
final class DocumentStore: ObservableObject, DocumentStoreProtocol {
    @Published private(set) var documents: [Document] = []
    var documentsPublisher: Published<[Document]>.Publisher { $documents }

    private let fm = FileManager.default
    private let rootURL: URL

    init() {
        let base = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.rootURL = base.appendingPathComponent("Documents", isDirectory: true)
        try? fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
        Task { await reload() }
    }

    // MARK: - Reload

    func reload() async {
        let loaded: [Document] = (try? loadAll()) ?? []
        self.documents = loaded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func loadAll() throws -> [Document] {
        let dirs = (try? fm.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)) ?? []
        return dirs.compactMap { dir -> Document? in
            let manifest = dir.appendingPathComponent("document.json")
            guard let data = try? Data(contentsOf: manifest) else { return nil }
            return try? JSONDecoder.iso.decode(Document.self, from: data)
        }
    }

    // MARK: - CRUD

    @discardableResult
    func createDocument(name: String) -> Document {
        let doc = Document(name: name)
        let folder = folderURL(for: doc.id)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        save(doc)
        documents.insert(doc, at: 0)
        return doc
    }

    func update(_ document: Document) {
        var d = document
        d.updatedAt = Date()
        save(d)
        if let idx = documents.firstIndex(where: { $0.id == d.id }) {
            documents[idx] = d
        } else {
            documents.insert(d, at: 0)
        }
        documents.sort { $0.updatedAt > $1.updatedAt }
    }

    func delete(_ document: Document) {
        try? fm.removeItem(at: folderURL(for: document.id))
        documents.removeAll { $0.id == document.id }
    }

    func rename(_ document: Document, to newName: String) {
        var d = document
        d.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if d.name.isEmpty { d.name = "Untitled" }
        update(d)
    }

    // MARK: - Pages

    @discardableResult
    func appendPage(toDocumentID id: UUID, image: UIImage) -> ScannedPage? {
        guard var doc = document(with: id) else { return nil }
        let pageID = UUID()
        let filename = "\(pageID.uuidString).jpg"
        let url = folderURL(for: id).appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print("[DocumentStore] write failed:", error)
            return nil
        }
        let page = ScannedPage(id: pageID, imageFile: filename)
        doc.pages.append(page)
        update(doc)
        return page
    }

    func updatePage(_ page: ScannedPage, inDocumentID id: UUID) {
        guard var doc = document(with: id) else { return }
        guard let idx = doc.pages.firstIndex(where: { $0.id == page.id }) else { return }
        doc.pages[idx] = page
        update(doc)
    }

    func deletePage(_ page: ScannedPage, fromDocumentID id: UUID) {
        guard var doc = document(with: id) else { return }
        let url = folderURL(for: id).appendingPathComponent(page.imageFile)
        try? fm.removeItem(at: url)
        doc.pages.removeAll { $0.id == page.id }
        update(doc)
    }

    func reorderPages(inDocumentID id: UUID, pages: [ScannedPage]) {
        guard var doc = document(with: id) else { return }
        doc.pages = pages
        update(doc)
    }

    // MARK: - Image access

    func loadImage(for page: ScannedPage, inDocumentID id: UUID) -> UIImage? {
        let url = imageURL(for: page, inDocumentID: id)
        return UIImage(contentsOfFile: url.path)
    }

    func imageURL(for page: ScannedPage, inDocumentID id: UUID) -> URL {
        folderURL(for: id).appendingPathComponent(page.imageFile)
    }

    func document(with id: UUID) -> Document? {
        documents.first { $0.id == id }
    }

    // MARK: - Helpers

    private func folderURL(for id: UUID) -> URL {
        rootURL.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    private func save(_ document: Document) {
        let folder = folderURL(for: document.id)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("document.json")
        do {
            let data = try JSONEncoder.iso.encode(document)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[DocumentStore] save failed:", error)
        }
    }
}

private extension JSONEncoder {
    static var iso: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

private extension JSONDecoder {
    static var iso: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
