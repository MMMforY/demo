import SwiftUI

struct AnalyticsDetailView: View {
    let summary: AnalyticsSummary
    let store: MockDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DemoPage {
            Text(DemoFormat.dateRange(start: summary.startDate, end: summary.endDate))
                .font(DemoTheme.Typography.caption)
            ForEach(summary.performances) { performance in
                DemoCard {
                    Text("\(store.plan(id: performance.planID)?.displayName ?? "方案不可用") · V\(performance.planVersion)")
                        .font(DemoTheme.Typography.heading)
                    DemoValueRow(title: "触达人数", value: "\(DemoFormat.count(performance.metrics.reachedCustomers)) 人")
                    DemoValueRow(title: "成交人数", value: "\(DemoFormat.count(performance.metrics.convertedCustomers)) 人")
                    DemoValueRow(title: "订单数", value: "\(DemoFormat.count(performance.metrics.orderCount)) 单")
                    DemoValueRow(title: "成交金额", value: DemoFormat.currency(cents: performance.metrics.revenueInCents))
                    DemoValueRow(title: "成交转化率", value: DemoFormat.percent(performance.metrics.conversionRate))
                }
            }
            Text("成交转化率 = 成交人数 ÷ 触达人数。此样本为同组互斥客户，合计转化率为 8.40%，不取两组平均值。")
                .font(DemoTheme.Typography.caption)
                .foregroundStyle(DemoTheme.ColorToken.secondaryText)
            DemoEmptyState(title: "数据详情占位", message: "时间与编号筛选、趋势图和更多指标将在后续补充。数据为历史固定样本，与待审批任务互不联动。")
            Button("返回数据首页") { dismiss() }.buttonStyle(DemoSecondaryButtonStyle())
        }
        .navigationTitle("方案效果对比")
        .navigationBarTitleDisplayMode(.inline)
    }
}
