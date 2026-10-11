import SwiftUI

struct DemoCard<Content: View>: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: DemoTheme.Spacing.medium) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DemoTheme.Spacing.large)
            .background(DemoTheme.ColorToken.cardBackground,
                        in: RoundedRectangle(cornerRadius: DemoTheme.Radius.card))
    }
}

struct DemoValueRow: View {
    let title: String
    let value: String
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: DemoTheme.Spacing.medium) {
                Text(title).foregroundStyle(DemoTheme.ColorToken.secondaryText)
                Spacer(minLength: DemoTheme.Spacing.small)
                Text(value).multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: DemoTheme.Spacing.small) {
                Text(title).foregroundStyle(DemoTheme.ColorToken.secondaryText)
                Text(value)
            }
        }
        .font(DemoTheme.Typography.body)
        .accessibilityElement(children: .combine)
    }
}
