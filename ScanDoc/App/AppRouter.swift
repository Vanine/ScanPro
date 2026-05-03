//
//  AppRouter.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/09/2025.
//  Coordinator-style navigation. Views call router methods only —
//  they never construct destinations themselves.
//

import SwiftUI
import Combine

/// All routable destinations in the app.
enum Route: Hashable {
    case documentDetail(documentID: UUID)
    case ocrResult(documentID: UUID, pageID: UUID)
    case pageEditor(documentID: UUID, pageID: UUID)
    case search
}

/// Modal sheets.
enum Sheet: Identifiable {
    case scanner(documentID: UUID?) // nil => create new doc
    case sharePDF(url: URL)
    case shareText(text: String)
    case rename(documentID: UUID, currentName: String)

    var id: String {
        switch self {
        case .scanner(let id): return "scanner-\(id?.uuidString ?? "new")"
        case .sharePDF(let url): return "pdf-\(url.absoluteString)"
        case .shareText(let s): return "text-\(s.hashValue)"
        case .rename(let id, _): return "rename-\(id.uuidString)"
        }
    }
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: Sheet?

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func present(_ sheet: Sheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        self.sheet = nil
    }
}
