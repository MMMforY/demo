import SwiftUI

struct AnalyticsHomeView: View {
    let store: MockDataStore
    var body: some View {
        DemoPage {
            DemoIntro(description: "在相同时间范围查看营销效果。")
            DemoCard {
                Text("近 7 日 · 固定样本").font(DemoTheme.Typography.heading)
                Text(DemoFormat.dateRange(start: store.analytics.startDate, end: store.analytics.endDate))
                    .font(DemoTheme.Typography.caption)
                DemoValueRow(title: "人群", value: store.audience(id: store.analytics.audienceID)?.displayName ?? "—")
                DemoValueRow(title: "方案", value: store.analytics.performances.compactMap { store.plan(id: $0.planID)?.displayName }.joined(separator: "／"))
            }
            DemoCard {
                Text("效果摘要 · 历史批次").font(DemoTheme.Typography.heading)
                DemoValueRow(title: "触达人数", value: "\(DemoFormat.count(store.analytics.totals.reachedCustomers)) 人")
                DemoValueRow(title: "成交人数", value: "\(DemoFormat.count(store.analytics.totals.convertedCustomers)) 人")
                DemoValueRow(title: "订单数", value: "\(DemoFormat.count(store.analytics.totals.orderCount)) 单")
                DemoValueRow(title: "成交金额", value: DemoFormat.currency(cents: store.analytics.totals.revenueInCents))
                DemoValueRow(title: "成交转化率", value: DemoFormat.percent(store.analytics.totals.conversionRate))
            }
            NavigationLink("查看方案对比详情") {
                AnalyticsDetailView(summary: store.analytics, store: store)
            }
            .buttonStyle(DemoPrimaryButtonStyle())
            .accessibilityIdentifier("analytics.detail")
        }
        .navigationTitle("数据")
    }
}
