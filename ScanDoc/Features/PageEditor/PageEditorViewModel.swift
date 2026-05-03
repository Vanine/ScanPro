//
//  PageEditorViewModel.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/10/2025.

import Foundation
import UIKit
import Combine

@MainActor
final class PageEditorViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case processing
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var displayedImage: UIImage?
    @Published var selectedFilter: ScanFilter = .original

    let documentID: UUID
    let pageID: UUID
    private let store: DocumentStoreProtocol
    private let filterService: ImageFilterServiceProtocol
    private var originalImage: UIImage?

    init(
        documentID: UUID,
        pageID: UUID,
        store: DocumentStoreProtocol,
        filterService: ImageFilterServiceProtocol
    ) {
        self.documentID = documentID
        self.pageID = pageID
        self.store = store
        self.filterService = filterService
    }

    func load() {
        guard let doc = store.document(with: documentID),
              let page = doc.pages.first(where: { $0.id == pageID }),
              let img = store.loadImage(for: page, inDocumentID: documentID)
        else {
            state = .error("Page not found")
            return
        }
        originalImage = img
        displayedImage = img
    }

    func apply(_ filter: ScanFilter) async {
        guard let original = originalImage else { return }
        selectedFilter = filter
        state = .processing
        let result = await Task.detached(priority: .userInitiated) { [filterService] in
            filterService.apply(filter, to: original)
        }.value
        displayedImage = result
        state = .idle
    }

    func rotate() {
        guard let img = displayedImage,
              let rotated = img.rotated(byDegrees: 90) else { return }
        displayedImage = rotated
        originalImage = rotated
    }

    func save() {
        guard let img = displayedImage else { return }
        // Rewrite the image file in place.
        guard let doc = store.document(with: documentID),
              let page = doc.pages.first(where: { $0.id == pageID }) else { return }
        let url = store.imageURL(for: page, inDocumentID: documentID)
        if let data = img.jpegData(compressionQuality: 0.9) {
            try? data.write(to: url, options: .atomic)
            // Touch document timestamp.
            store.update(doc)
        }
    }
}

private extension UIImage {
    func rotated(byDegrees degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        ctx.rotate(by: radians)
        draw(in: CGRect(
            x: -size.width / 2, y: -size.height / 2,
            width: size.width, height: size.height
        ))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
