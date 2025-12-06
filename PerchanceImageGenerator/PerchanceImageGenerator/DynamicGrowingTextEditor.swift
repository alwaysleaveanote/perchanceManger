import SwiftUI
import UIKit

struct DynamicGrowingTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minLines: Int
    let maxLines: Int

    @State private var height: CGFloat = 40

    var body: some View {
        GrowingTextView(
            text: $text,
            calculatedHeight: $height,
            placeholder: placeholder,
            minLines: minLines,
            maxLines: maxLines
        )
        .frame(minHeight: height, maxHeight: height)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat

    let placeholder: String
    let minLines: Int
    let maxLines: Int

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.delegate = context.coordinator
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear

        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.textContainerInset = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        textView.textContainer.lineFragmentPadding = 0

        // Placeholder when empty
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.placeholderText
        } else {
            textView.text = text
        }

        // ✅ Add a toolbar with a Done button above the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexible = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )

        toolbar.items = [flexible, done]
        textView.inputAccessoryView = toolbar

        // Initial height
        DispatchQueue.main.async {
            recalcHeight(textView: textView)
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Keep placeholder behavior in sync
        if text.isEmpty {
            if uiView.text != placeholder || uiView.textColor != UIColor.placeholderText {
                uiView.text = placeholder
                uiView.textColor = UIColor.placeholderText
            }
        } else {
            if uiView.text != text || uiView.textColor == UIColor.placeholderText {
                uiView.text = text
                uiView.textColor = UIColor.label
            }
        }

        recalcHeight(textView: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView

        init(_ parent: GrowingTextView) {
            self.parent = parent
        }
        
        @objc func doneTapped() {
            // Dismiss the keyboard globally
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }


        func textViewDidBeginEditing(_ textView: UITextView) {
            // Clear placeholder when editing begins
            if textView.textColor == UIColor.placeholderText {
                textView.text = ""
                textView.textColor = UIColor.label
            }
        }
        

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.recalcHeight(textView: textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.placeholderText
                parent.text = ""
            }
            parent.recalcHeight(textView: textView)
        }
    }

    // MARK: - Height calculation

    private func recalcHeight(textView: UITextView) {
        // Measure the natural height
        let fittingWidth = textView.bounds.width > 0
            ? textView.bounds.width
            : UIScreen.main.bounds.width - 40
    


        let fittingSize = CGSize(width: fittingWidth,
                                 height: .greatestFiniteMagnitude)

        let size = textView.sizeThatFits(fittingSize)

        let font = textView.font ?? UIFont.preferredFont(forTextStyle: .body)
        let lineHeight = font.lineHeight

        // Target heights based on min/max lines
        let minHeight = lineHeight * CGFloat(max(minLines, 0))
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom

        let maxHeight = lineHeight * CGFloat(max(maxLines, minLines))
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom

        // Clamp measured height
        var newHeight = size.height

        if newHeight < minHeight {
            newHeight = minHeight
        } else if newHeight > maxHeight {
            newHeight = maxHeight
        }

        // Small extra padding to avoid bottom clipping
        newHeight += 6

        // Avoid feedback loops
        if abs(calculatedHeight - newHeight) > 0.5 {
            DispatchQueue.main.async {
                calculatedHeight = newHeight
            }
        }
    }
}
