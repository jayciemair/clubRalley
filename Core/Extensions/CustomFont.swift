//
//  CustomFont.swift
//  Dial
//

import Foundation
import SwiftUI

// Transitioning to SF Pro Display system font
private func satoshiFontName(for weight: Font.Weight) -> String {
    switch weight {
    case .black:
        return "Satoshi-Black"
    case .bold, .semibold:
        return "Satoshi-Bold"
    case .medium:
        return "Satoshi-Medium"
    case .light:
        return "Satoshi-Light"
    default:
        return "Satoshi-Regular"
    }
}

private func baseSize(for textStyle: Font.TextStyle) -> CGFloat {
    switch textStyle {
    case .largeTitle: return 34
    case .title: return 28
    case .title2: return 22
    case .title3: return 20
    case .headline: return 17
    case .subheadline: return 15
    case .callout: return 16
    case .footnote: return 13
    case .caption: return 12
    case .caption2: return 11
    default: return 17 // body
    }
}

struct CustomFont: ViewModifier {
    var textStyle: Font.TextStyle
    
    var weight: Font.Weight {
        switch textStyle {
        case .largeTitle, .title, .title2, .title3:
            return .bold
        case .headline, .subheadline:
            return .semibold
        case .body, .callout:
            return .medium
        case .footnote, .caption, .caption2:
            return .regular
        default:
            return .regular
        }
    }
    
    func body(content: Content) -> some View {
        let name = satoshiFontName(for: weight)
        content.font(.custom(name, size: baseSize(for: textStyle), relativeTo: textStyle))
    }
}

extension View {
    func customFont(_ textStyle: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        Group {
            if let weight = weight {
                let name = satoshiFontName(for: weight)
                self.font(.custom(name, size: baseSize(for: textStyle), relativeTo: textStyle))
            } else {
                self.modifier(CustomFont(textStyle: textStyle))
            }
        }
    }
}

// Text style enum for consistency
extension Font.TextStyle {
    static let subheadline2 = Font.TextStyle.footnote
}