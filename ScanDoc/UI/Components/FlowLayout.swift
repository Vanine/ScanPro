//
//  FlowLayout.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/31/2025.
//  Simple wrapping flow layout for tag chips. Uses SwiftUI's Layout API.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        return layout(in: width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (idx, frame) in result.frames.enumerated() {
            let pos = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[idx].place(at: pos, anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private struct Result {
        var size: CGSize
        var frames: [CGRect]
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> Result {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxWidth = max(maxWidth, x)
        }
        return Result(size: CGSize(width: maxWidth, height: y + rowHeight), frames: frames)
    }
}
