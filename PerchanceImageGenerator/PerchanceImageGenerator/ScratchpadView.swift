//
//  ScratchpadView.swift
//  PerchanceImageGenerator
//
//  Created by Alex Gingras on 12/5/25.
//


import SwiftUI

struct ScratchpadView: View {
    @Binding var scratchpadPrompt: String
    @Binding var scratchpadSaved: [SavedPrompt]

    let openGenerator: (String) -> Void

    @State private var status: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scratchpad")
                        .font(.headline)

                    TextEditor(text: $scratchpadPrompt)
                        .frame(height: 120)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    HStack {
                        Button("Copy") {
                            UIPasteboard.general.string = scratchpadPrompt
                            status = "Copied scratchpad to clipboard."
                        }

                        Spacer()

                        Button("Save as scratch") {
                            let title = makeTitle(from: scratchpadPrompt)
                            let newPrompt = SavedPrompt(title: title,
                                                        text: scratchpadPrompt)
                            scratchpadSaved.insert(newPrompt, at: 0)
                            status = "Saved scratch: \(title)"
                        }
                    }
                    .font(.subheadline)

                    Button {
                        openGenerator(scratchpadPrompt)
                        status = "Prompt copied. Opening furry-ai…"
                    } label: {
                        HStack {
                            Spacer()
                            Text("Open Furry Generator with Scratchpad")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, 4)

                    if !status.isEmpty {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Divider()

                List {
                    Section(header: Text("Saved Scratch Prompts")) {
                        if scratchpadSaved.isEmpty {
                            Text("No saved scratch prompts yet.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(scratchpadSaved) { prompt in
                                VStack(alignment: .leading) {
                                    Text(prompt.title)
                                        .font(.subheadline)
                                        .bold()
                                    Text(prompt.text)
                                        .font(.caption)
                                        .lineLimit(3)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    scratchpadPrompt = prompt.text
                                    status = "Loaded scratch: \(prompt.title)"
                                }
                            }
                            .onDelete { indices in
                                scratchpadSaved.remove(atOffsets: indices)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Scratchpad")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.dismiss()
                    }
                }
            }

        }

    }

    private func makeTitle(from prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Untitled Scratch" }
        let prefix = trimmed.prefix(40)
        return String(prefix) + (trimmed.count > 40 ? "…" : "")
    }
}
