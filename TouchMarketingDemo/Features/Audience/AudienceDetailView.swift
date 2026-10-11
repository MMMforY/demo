import SwiftUI

struct AudienceDetailView: View {
    let audience: Audience
    let store: MockDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DemoPage {
            DemoCard {
                DemoValueRow(title: "覆盖人数", value: "\(DemoFormat.count(audience.memberCount)) 人")
                DemoValueRow(title: "来源", value: audience.source.rawValue)
                DemoValueRow(title: "版本", value: "V\(audience.version)")
            }
            DemoCard {
                Text("六项画像 · 示例").font(DemoTheme.Typography.heading)
                ForEach(audience.scores) { score in
                    DemoValueRow(title: score.dimension.rawValue, value: score.displayValue)
                }
                Text("主要品类").font(DemoTheme.Typography.heading)
                ForEach(audience.categoryPreferences) { category in
                    DemoValueRow(title: category.name, value: "\(category.percentage)%")
                }
            }
            DemoCard {
                Text("关联方案").font(DemoTheme.Typography.heading)
                Text(store.plans(for: audience).map(\.displayName).joined(separator: "、"))
            }
            DemoEmptyState(title: "人群详情占位", message: "规则编辑、历史版本和 AI 建议将在后续补充。当前评分为固定示例。")
            Button("返回人群首页") { dismiss() }.buttonStyle(DemoSecondaryButtonStyle())
        }
        .navigationTitle(audience.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
