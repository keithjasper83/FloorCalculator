//
//  ViewExtensions.swift
//  FloorPlanner
//
//  Platform-specific view extensions
//

import SwiftUI

#if os(macOS)
enum UIKeyboardType {
    case `default`
    case asciiCapable
    case numbersAndPunctuation
    case URL
    case numberPad
    case phonePad
    case namePhonePad
    case emailAddress
    case decimalPad
    case twitter
    case webSearch
    case asciiCapableNumberPad
}

extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View {
        self
    }

    func navigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View {
        self
    }
}
#endif
