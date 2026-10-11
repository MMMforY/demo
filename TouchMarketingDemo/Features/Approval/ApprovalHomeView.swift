import SwiftUI

struct ApprovalHomeView: View {
    let store: MockDataStore
    var body: some View {
        DemoPage {
            DemoIntro(description: "发送前核对人群、方案和 A/B 分配。")
            Text("待审批任务").font(DemoTheme.Typography.title)
            ForEach(store.approvalTasks.filter { $0.approvalStatus == .pending }) { task in
                DemoCard {
                    Text(task.displayName).font(DemoTheme.Typography.heading)
                    DemoValueRow(title: "状态", value: task.approvalStatus.rawValue)
                    DemoValueRow(title: "目标人群", value: store.audience(id: task.audienceID)?.displayName ?? "人群不可用")
                    DemoValueRow(title: "预计触达", value: "\(DemoFormat.count(task.expectedReach)) 人")
                    ForEach(task.allocation.groups) { group in
                        DemoValueRow(title: store.plan(id: group.planID)?.displayName ?? "方案不可用", value: "\(group.percentage)%")
                    }
                    NavigationLink("查看任务详情") {
                        ApprovalDetailView(task: task, store: store)
                    }
                    .buttonStyle(DemoPrimaryButtonStyle())
                    .accessibilityIdentifier("approval.\(task.id)")
                }
            }
            Text("规则只生成待审批任务，所有发送都需人工确认。")
                .font(DemoTheme.Typography.caption)
                .foregroundStyle(DemoTheme.ColorToken.secondaryText)
        }
        .navigationTitle("发送审批")
    }
}
