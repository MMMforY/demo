import SwiftUI

struct AudienceHomeView: View {
    let store: MockDataStore
    var body: some View {
        DemoPage {
            DemoIntro(description: "了解客户的宏观画像，为营销选择合适的人群。")
            Text("\(store.audiences.count) 个人群").font(DemoTheme.Typography.title)
            ForEach(store.audiences) { audience in
                NavigationLink {
                    AudienceDetailView(audience: audience, store: store)
                } label: {
                    DemoCard {
                        HStack {
                            Text(audience.displayName).font(DemoTheme.Typography.heading)
                            Spacer()
                            Image(systemName: "chevron.right").accessibilityHidden(true)
                        }
                        DemoValueRow(title: "覆盖人数", value: "\(DemoFormat.count(audience.memberCount)) 人")
                        ForEach(audience.scores.prefix(3)) { score in
                            DemoValueRow(title: score.dimension.rawValue, value: score.displayValue)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("audience.\(audience.id)")
            }
            Text("人群可能交叉，覆盖人数不可直接相加。")
                .font(DemoTheme.Typography.caption)
                .foregroundStyle(DemoTheme.ColorToken.secondaryText)
        }
        .navigationTitle("人群")
    }
}
