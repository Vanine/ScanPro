//
//  RootView.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 01/11/2025.
//  Hosts the NavigationStack and routes Route values to feature views.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var deps: AppDependencies
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: HomeViewModel(store: deps.documentStore))
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .environmentObject(router)
        .sheet(item: $router.sheet) { sheet in
            sheetView(for: sheet)
                .environmentObject(router)
                .environmentObject(deps)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .documentDetail(let id):
            DocumentDetailView(
                viewModel: DocumentDetailViewModel(
                    documentID: id,
                    store: deps.documentStore,
                    pdfService: deps.pdfService
                )
            )
        case .ocrResult(let docID, let pageID):
            OCRView(
                viewModel: OCRViewModel(
                    documentID: docID,
                    pageID: pageID,
                    store: deps.documentStore,
                    ocrService: deps.ocrService
                )
            )
        case .pageEditor(let docID, let pageID):
            PageEditorView(
                viewModel: PageEditorViewModel(
                    documentID: docID,
                    pageID: pageID,
                    store: deps.documentStore,
                    filterService: deps.imageFilterService
                )
            )
        case .search:
            SearchView(
                viewModel: SearchViewModel(store: deps.documentStore)
            )
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .scanner(let docID):
            ScannerSheet(
                documentID: docID,
                store: deps.documentStore,
                ocrService: deps.ocrService
            )
            .ignoresSafeArea()
        case .sharePDF(let url):
            ShareSheet(items: [url])
        case .shareText(let text):
            ShareSheet(items: [text])
        case .rename(let id, let name):
            RenameSheet(documentID: id, currentName: name, store: deps.documentStore)
                .presentationDetents([.height(220)])
        }
    }
}
