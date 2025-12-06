import SwiftUI

/// A SwiftUI-only growing text editor with:
/// - placeholder as overlay
/// - dynamic height between `minLines` and `maxLines`
/// - proper line wrapping
/// - theme support
struct DynamicGrowingTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minLines: Int
    let maxLines: Int
    let fontSize: CGFloat
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var measuredHeight: CGFloat = 0
    
    private var lineHeight: CGFloat {
        UIFont.systemFont(ofSize: fontSize).lineHeight
    }
    
    private var textFont: Font {
        .system(size: fontSize)
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
        maxLines: Int = 10,
        fontSize: CGFloat = 16
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minLines = minLines
        self.maxLines = maxLines
        self.fontSize = fontSize
    }
    
    public var body: some View {
        let theme = themeManager.resolved
        
        ZStack(alignment: .topLeading) {
            
            // Actual editor (on the bottom)
            TextEditor(text: $text)
                .font(textFont)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(
                    minHeight: minHeight,
                    maxHeight: min(
                        max(measuredHeight, minHeight),
                        maxHeight
                    )
                )
                .background(theme.backgroundTertiary)
                .background(
                    HeightReader(text: text, height: $measuredHeight)
                )
            
            // Placeholder overlay (ON TOP of the editor)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !placeholder.isEmpty {
                Text(placeholder)
                    .font(textFont)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)  // so taps still focus the TextEditor
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .stroke(theme.border.opacity(0.5), lineWidth: 1)
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
