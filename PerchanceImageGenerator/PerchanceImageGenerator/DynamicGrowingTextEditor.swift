import SwiftUI

/// A SwiftUI-only growing text editor with:
/// - placeholder as overlay
/// - dynamic height between `minLines` and `maxLines`
/// - proper line wrapping
struct DynamicGrowingTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minLines: Int
    let maxLines: Int

    @State private var measuredHeight: CGFloat = 0

    private var lineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).lineHeight
    }

    private var minHeight: CGFloat {
        CGFloat(max(minLines, 1)) * lineHeight + 16 // padding
    }

    private var maxHeight: CGFloat {
        CGFloat(max(maxLines, minLines)) * lineHeight + 16 // padding
    }

    public init(
        text: Binding<String>,
        placeholder: String,
        minLines: Int = 1,
        maxLines: Int = 10
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minLines = minLines
        self.maxLines = maxLines
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder overlay (never part of the model)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }

            // Actual editor
            TextEditor(text: $text)
                .font(.body)
                .frame(
                    minHeight: minHeight,
                    maxHeight: min(
                        max(measuredHeight, minHeight),
                        maxHeight
                    )
                )
                .background(
                    HeightReader(text: text, height: $measuredHeight)
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }
}

/// A helper view that measures the height of the given text
/// using the same font & width as the TextEditor.
private struct HeightReader: View {
    let text: String
    @Binding var height: CGFloat

    var body: some View {
        GeometryReader { _ in
            Text(text.isEmpty ? " " : text)
                .font(.body)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { innerGeo in
                        Color.clear
                            .onAppear {
                                updateHeight(innerGeo)
                            }
                            .onChange(of: innerGeo.size.height) { _, _ in
                                updateHeight(innerGeo)
                            }
                    }
                )
                .opacity(0) // invisible, just for measurement
        }
    }

    private func updateHeight(_ geo: GeometryProxy) {
        let newHeight = geo.size.height
        if abs(newHeight - height) > 0.5 {
            DispatchQueue.main.async {
                height = newHeight
            }
        }
    }
}
