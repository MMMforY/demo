import SwiftUI

struct PlanHomeView: View {
    let store: MockDataStore
    var body: some View {
        DemoPage {
            DemoIntro(description: "按目的与适用客户查看营销方案。")
            Text("\(store.plans.count) 套方案").font(DemoTheme.Typography.title)
            ForEach(store.plans) { plan in
                NavigationLink {
                    PlanDetailView(plan: plan, store: store)
                } label: {
                    DemoCard {
                        HStack {
                            Text(plan.displayName).font(DemoTheme.Typography.heading)
                            Spacer()
                            Image(systemName: "chevron.right").accessibilityHidden(true)
                        }
                        DemoValueRow(title: "目的", value: plan.purpose.rawValue)
                        DemoValueRow(title: "适用客户", value: plan.customerStage.rawValue)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("plan.\(plan.id)")
            }
        }
        .navigationTitle("方案")
    }
}
