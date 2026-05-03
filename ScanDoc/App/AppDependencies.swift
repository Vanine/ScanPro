//
//  AppDependencies.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/07/2025.
//  Lightweight protocol-based DI container.
//  ViewModels receive only the protocols they need, never concrete types.
//

import Foundation
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    let documentStore: DocumentStoreProtocol
    let ocrService: OCRServiceProtocol
    let pdfService: PDFServiceProtocol
    let imageFilterService: ImageFilterServiceProtocol

    init(
        documentStore: DocumentStoreProtocol,
        ocrService: OCRServiceProtocol,
        pdfService: PDFServiceProtocol,
        imageFilterService: ImageFilterServiceProtocol
    ) {
        self.documentStore = documentStore
        self.ocrService = ocrService
        self.pdfService = pdfService
        self.imageFilterService = imageFilterService
    }

    /// Production wiring.
    static func live() -> AppDependencies {
        let store = DocumentStore()
        return AppDependencies(
            documentStore: store,
            ocrService: OCRService(),
            pdfService: PDFService(),
            imageFilterService: ImageFilterService()
        )
    }
}
