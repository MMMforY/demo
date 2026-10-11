import SwiftUI

enum DemoTheme {
    enum ColorToken {
        static let black = Color.black
        static let white = Color.white
        static let gray = Color(white: 0.42)
        static let pageBackground = Color(.systemBackground)
        static let cardBackground = Color(white: 0.96)
        static let primaryText = black
        static let secondaryText = gray
        static let border = Color(white: 0.85)
    }
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let page: CGFloat = 20
        static let section: CGFloat = 24
    }
    enum Radius {
        static let button: CGFloat = 12
        static let card: CGFloat = 16
    }
    enum Typography {
        static let title = Font.title2.weight(.semibold)
        static let heading = Font.headline
        static let body = Font.body
        static let caption = Font.footnote
    }
}
