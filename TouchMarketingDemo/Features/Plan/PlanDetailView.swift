import SwiftUI

struct PlanDetailView: View {
    let plan: MarketingPlan
    let store: MockDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DemoPage {
            DemoCard {
                DemoValueRow(title: "目的", value: plan.purpose.rawValue)
                DemoValueRow(title: "适用客户", value: plan.customerStage.rawValue)
                DemoValueRow(title: "版本", value: "V\(plan.version)")
                DemoValueRow(title: "来源", value: plan.source.rawValue)
            }
            DemoCard {
                Text("话术示例").font(DemoTheme.Typography.heading)
                Text(plan.message).font(DemoTheme.Typography.body)
                DemoValueRow(title: "搭配内容", value: plan.resourceSummary)
                DemoValueRow(title: "关联人群", value: plan.audienceIDs.compactMap { store.audience(id: $0)?.displayName }.joined(separator: "、"))
            }
            DemoEmptyState(title: "方案详情占位", message: "创建编辑、店铺资源选择和历史版本将在后续补充。此处资源仅为本地说明。")
            Button("返回方案首页") { dismiss() }.buttonStyle(DemoSecondaryButtonStyle())
        }
        .navigationTitle(plan.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
