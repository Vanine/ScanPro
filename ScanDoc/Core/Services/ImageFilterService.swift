//
//  ImageFilterService.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/17/2025.
//  CoreImage-backed enhancement filters used in the page editor.
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum ScanFilter: String, CaseIterable, Identifiable, Codable {
    case original
    case enhanced
    case blackAndWhite
    case grayscale

    var id: String { rawValue }
    var label: String {
        switch self {
        case .original: return "Original"
        case .enhanced: return "Enhanced"
        case .blackAndWhite: return "B&W"
        case .grayscale: return "Grayscale"
        }
    }
}

protocol ImageFilterServiceProtocol: Sendable {
    func apply(_ filter: ScanFilter, to image: UIImage) -> UIImage
    func thumbnail(for image: UIImage, maxSize: CGFloat) -> UIImage
}

final class ImageFilterService: ImageFilterServiceProtocol, @unchecked Sendable {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func apply(_ filter: ScanFilter, to image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let output: CIImage?

        switch filter {
        case .original:
            return image
        case .enhanced:
            let f = CIFilter.colorControls()
            f.inputImage = ci
            f.contrast = 1.25
            f.brightness = 0.05
            f.saturation = 1.1
            output = f.outputImage
        case .blackAndWhite:
            let mono = CIFilter.colorControls()
            mono.inputImage = ci
            mono.saturation = 0
            mono.contrast = 1.6
            mono.brightness = 0.1
            guard let g = mono.outputImage else { return image }
            let tone = CIFilter.exposureAdjust()
            tone.inputImage = g
            tone.ev = 0.4
            output = tone.outputImage
        case .grayscale:
            let f = CIFilter.photoEffectMono()
            f.inputImage = ci
            output = f.outputImage
        }

        guard let out = output,
              let cgOut = context.createCGImage(out, from: out.extent) else {
            return image
        }
        return UIImage(cgImage: cgOut, scale: image.scale, orientation: image.imageOrientation)
    }

    func thumbnail(for image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxSize / size.width, maxSize / size.height, 1)
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
