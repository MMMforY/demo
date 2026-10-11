import SwiftUI

struct DemoEmptyState: View {
    let title: String
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: DemoTheme.Spacing.small) {
            Text(title).font(DemoTheme.Typography.heading)
            Text(message)
                .font(DemoTheme.Typography.caption)
                .foregroundStyle(DemoTheme.ColorToken.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DemoTheme.Spacing.large)
        .overlay(RoundedRectangle(cornerRadius: DemoTheme.Radius.card)
            .stroke(DemoTheme.ColorToken.border, lineWidth: 1))
    }
}
