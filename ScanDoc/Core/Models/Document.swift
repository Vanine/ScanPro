//
//  Document.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/13/2025.
//  Domain models. Plain Codable values — persistence layer owns IO.
//

import Foundation

struct Document: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var pages: [ScannedPage]
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        pages: [ScannedPage] = [],
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pages = pages
        self.tags = tags
    }

    /// Combined OCR text from all pages (used for search).
    var combinedText: String {
        pages.compactMap { $0.recognizedText }.joined(separator: "\n\n")
    }

    var pageCount: Int { pages.count }
}

struct ScannedPage: Identifiable, Codable, Hashable {
    let id: UUID
    /// Filename relative to the document folder.
    var imageFile: String
    var recognizedText: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imageFile: String,
        recognizedText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageFile = imageFile
        self.recognizedText = recognizedText
        self.createdAt = createdAt
    }
}
