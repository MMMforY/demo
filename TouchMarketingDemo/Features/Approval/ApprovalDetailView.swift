import SwiftUI

struct ApprovalDetailView: View {
    let task: ApprovalTask
    let store: MockDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DemoPage {
            DemoCard {
                DemoValueRow(title: "状态", value: task.approvalStatus.rawValue)
                DemoValueRow(title: "目标人群", value: store.audience(id: task.audienceID)?.displayName ?? "人群不可用")
                DemoValueRow(title: "人群版本", value: "V\(task.audienceVersion)")
                DemoValueRow(title: "预计触达", value: "\(DemoFormat.count(task.expectedReach)) 人")
                if let audience = store.audience(id: task.audienceID) {
                    ForEach(audience.scores.prefix(3)) { score in
                        DemoValueRow(title: score.dimension.rawValue, value: score.displayValue)
                    }
                }
            }
            DemoCard {
                Text("A/B 分配 · 固定示例").font(DemoTheme.Typography.heading)
                ForEach(Array(task.allocation.groups.enumerated()), id: \.element.id) { index, group in
                    let plan = store.plan(id: group.planID)
                    Text("\(index == 0 ? "A" : "B") 组 · \(plan?.displayName ?? "方案不可用") · V\(group.planVersion)")
                        .font(DemoTheme.Typography.heading)
                    DemoValueRow(title: "目的", value: plan?.purpose.rawValue ?? "—")
                    DemoValueRow(title: "适用客户", value: plan?.customerStage.rawValue ?? "—")
                    DemoValueRow(title: "比例", value: "\(group.percentage)%")
                    DemoValueRow(title: "预计人数", value: "\(DemoFormat.count(task.allocation.expectedCounts(total: task.expectedReach)[index])) 人")
                }
                Text("比例合计 100%，每位客户仅接收一套方案。")
                    .font(DemoTheme.Typography.caption)
                    .foregroundStyle(DemoTheme.ColorToken.secondaryText)
            }
            DemoEmptyState(title: "任务详情占位", message: "比例调整、确认、稍后处理、拒绝与重试将在后续补充。当前没有发送动作。")
            Button("返回发送审批首页") { dismiss() }.buttonStyle(DemoSecondaryButtonStyle())
        }
        .navigationTitle(task.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
