//
//  PDFService.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/21/2025.
//  PDF generation via UIGraphicsPDFRenderer. Pages are rendered at A4 size,
//  preserving aspect ratio with white background.
//

import Foundation
import UIKit
import PDFKit

protocol PDFServiceProtocol: Sendable {
    func makePDF(name: String, images: [UIImage]) throws -> URL
    func makeTextFile(name: String, text: String) throws -> URL
}

final class PDFService: PDFServiceProtocol, @unchecked Sendable {
    enum PDFError: LocalizedError {
        case noPages
        case writeFailed
        var errorDescription: String? {
            switch self {
            case .noPages: return "No pages to export."
            case .writeFailed: return "Could not write the file."
            }
        }
    }

    private let pageSize = CGSize(width: 595, height: 842) // A4 @ 72dpi

    func makePDF(name: String, images: [UIImage]) throws -> URL {
        guard !images.isEmpty else { throw PDFError.noPages }

        let safeName = sanitize(name)
        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("\(safeName).pdf")

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: safeName,
            kCGPDFContextCreator as String: "ScanDoc"
        ]
        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        do {
            try renderer.writePDF(to: url) { ctx in
                for image in images {
                    ctx.beginPage()
                    UIColor.white.setFill()
                    ctx.fill(bounds)
                    let rect = aspectFit(image.size, into: bounds.insetBy(dx: 24, dy: 24))
                    image.draw(in: rect)
                }
            }
        } catch {
            throw PDFError.writeFailed
        }
        return url
    }

    func makeTextFile(name: String, text: String) throws -> URL {
        let safeName = sanitize(name)
        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("\(safeName).txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw PDFError.writeFailed
        }
        return url
    }

    private func aspectFit(_ size: CGSize, into rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let w = size.width * scale
        let h = size.height * scale
        let x = rect.midX - w / 2
        let y = rect.midY - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func sanitize(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: " -_"))
        let cleaned = name.unicodeScalars.filter { allowed.contains($0) }
        let s = String(String.UnicodeScalarView(cleaned)).trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? "Document" : s
    }
}
