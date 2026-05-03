//
//  OCRService.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/19/2025.
//  Vision-based text recognition with bounding boxes for in-image highlights.
//  Background-queued, async/await API.
//

import Foundation
@preconcurrency import Vision
import UIKit

struct RecognizedTextBlock: Hashable, Codable {
    let text: String
    /// Normalized rect in Vision coordinates (origin bottom-left, 0..1).
    let boundingBox: CGRect
    let confidence: Float
}

struct OCRResult {
    let fullText: String
    let blocks: [RecognizedTextBlock]
}

protocol OCRServiceProtocol: Sendable {
    func recognize(image: UIImage, languages: [String]) async throws -> OCRResult
    var supportedLanguages: [String] { get }
}

final class OCRService: OCRServiceProtocol, @unchecked Sendable {
    enum OCRError: LocalizedError {
        case invalidImage
        case visionFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Could not read this image."
            case .visionFailed(let e): return "Recognition failed: \(e.localizedDescription)"
            }
        }
    }

    var supportedLanguages: [String] {
        ["en-US"]
    }

    func recognize(image: UIImage, languages: [String]) async throws -> OCRResult {
        guard let cg = image.cgImage else { throw OCRError.invalidImage }
        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err = err {
                    cont.resume(throwing: OCRError.visionFailed(err))
                    return
                }
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                var blocks: [RecognizedTextBlock] = []
                var lines: [String] = []
                for obs in observations {
                    guard let top = obs.topCandidates(1).first else { continue }
                    blocks.append(.init(
                        text: top.string,
                        boundingBox: obs.boundingBox,
                        confidence: top.confidence
                    ))
                    lines.append(top.string)
                }
                cont.resume(returning: OCRResult(
                    fullText: lines.joined(separator: "\n"),
                    blocks: blocks
                ))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if !languages.isEmpty {
                request.recognitionLanguages = languages
            }

            let handler = VNImageRequestHandler(cgImage: cg, orientation: image.cgOrientation, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    cont.resume(throwing: OCRError.visionFailed(error))
                }
            }
        }
    }
}

private extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
