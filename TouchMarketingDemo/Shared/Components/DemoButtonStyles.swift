import SwiftUI

struct DemoPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DemoTheme.Typography.heading)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, DemoTheme.Spacing.large)
            .background(DemoTheme.ColorToken.black,
                        in: RoundedRectangle(cornerRadius: DemoTheme.Radius.button))
            .foregroundStyle(DemoTheme.ColorToken.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct DemoSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DemoTheme.Typography.heading)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, DemoTheme.Spacing.large)
            .background(DemoTheme.ColorToken.white,
                        in: RoundedRectangle(cornerRadius: DemoTheme.Radius.button))
            .overlay(RoundedRectangle(cornerRadius: DemoTheme.Radius.button)
                .stroke(DemoTheme.ColorToken.border, lineWidth: 1))
            .foregroundStyle(DemoTheme.ColorToken.primaryText)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
