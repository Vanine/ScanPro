//
//  RenameSheet.swift
//  ScanDoc
//
//  Created by Vanine Ghazaryan on 02/18/2025.

import SwiftUI

struct RenameSheet: View {
    let documentID: UUID
    let currentName: String
    let store: DocumentStoreProtocol

    @EnvironmentObject private var router: AppRouter
    @State private var name: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Rename document")
                .font(.headline)
            TextField("Document name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(save)
            HStack {
                Button("Cancel", role: .cancel) {
                    router.dismissSheet()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Save", action: save)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .onAppear {
            name = currentName
            focused = true
        }
    }

    private func save() {
        if let doc = store.document(with: documentID) {
            store.rename(doc, to: name)
        }
        router.dismissSheet()
    }
}
