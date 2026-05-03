//
//  ScannerSheet.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/08/2025.
//  Wraps VisionKit's VNDocumentCameraViewController. It already gives us
//  edge detection, manual corner adjustment, perspective correction,
//  and built-in filter modes. Output images are appended to the target
//  document and OCR runs in the background.
//

import SwiftUI
import VisionKit
import UIKit

struct ScannerSheet: View {
    let documentID: UUID?
    let store: DocumentStoreProtocol
    let ocrService: OCRServiceProtocol

    @EnvironmentObject private var router: AppRouter

    var body: some View {
        DocumentCameraView { images in
            handleScan(images: images)
        } onCancel: {
            router.dismissSheet()
        }
    }

    @MainActor
    private func handleScan(images: [UIImage]) {
        guard !images.isEmpty else {
            router.dismissSheet()
            return
        }
        // Resolve target document.
        let doc: Document
        if let id = documentID, let existing = store.document(with: id) {
            doc = existing
        } else {
            let name = "Scan \(Self.dateFormatter.string(from: Date()))"
            doc = store.createDocument(name: name)
        }

        var addedPages: [(UUID, ScannedPage)] = []
        for image in images {
            if let page = store.appendPage(toDocumentID: doc.id, image: image) {
                addedPages.append((doc.id, page))
            }
        }

        // Run OCR for each page in the background.
        Task.detached(priority: .userInitiated) { [ocrService, store] in
            for (docID, page) in addedPages {
                guard let img = await store.loadImage(for: page, inDocumentID: docID) else { continue }
                do {
                    let result = try await ocrService.recognize(image: img, languages: [])
                    var updated = page
                    updated.recognizedText = result.fullText
                    await store.updatePage(updated, inDocumentID: docID)
                } catch {
                    print("[ScannerSheet] OCR failed:", error.localizedDescription)
                }
            }
        }

        router.dismissSheet()
        // Navigate to the new document if created from Home.
        if documentID == nil {
            router.push(.documentDetail(documentID: doc.id))
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()
}

private struct DocumentCameraView: UIViewControllerRepresentable {
    let onFinish: ([UIImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: ([UIImage]) -> Void
        let onCancel: () -> Void
        init(onFinish: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onFinish(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("[Scanner] failed:", error.localizedDescription)
            onCancel()
        }
    }
}
