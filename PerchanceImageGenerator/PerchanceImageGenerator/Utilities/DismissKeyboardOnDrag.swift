import SwiftUI

/// View modifier that dismisses keyboard on drag gesture
struct DismissKeyboardOnDrag: ViewModifier {
    func body(content: Content) -> some View {
        content.gesture(
            DragGesture().onChanged { _ in
                KeyboardHelper.dismiss()
            }
        )
    }
}

extension View {
    func dismissKeyboardOnDrag() -> some View {
        self.modifier(DismissKeyboardOnDrag())
    }
}
