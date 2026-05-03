//
//  DocumentRow.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/02/2025.

import SwiftUI

struct DocumentRow: View {
    let document: Document
    let thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius)
                    .fill(Theme.surfaceMuted)
                    .frame(width: 56, height: 72)
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.smallCornerRadius))
                } else {
                    Image(systemName: "doc.text")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.heroGradient)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius)
                    .stroke(Theme.separator.opacity(0.4), lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                    Text("•")
                    Text(document.updatedAt, style: .date)
                }
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
                if !document.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(document.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.accent.opacity(0.12))
                                .foregroundColor(Theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}
