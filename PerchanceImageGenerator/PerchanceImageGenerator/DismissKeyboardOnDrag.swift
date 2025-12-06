//
//  DismissKeyboardOnDrag.swift
//  PerchanceImageGenerator
//
//  Created by Alex Gingras on 12/5/25.
//


import SwiftUI

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
