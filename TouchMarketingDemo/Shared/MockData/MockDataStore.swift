import Foundation

/// 只读值容器。四个模块共用这一份 fixture，不执行网络、持久化或 AI 计算。
struct MockDataStore {
    let audiences: [Audience]
    let plans: [MarketingPlan]
    let approvalTasks: [ApprovalTask]
    let analytics: AnalyticsSummary

    func audience(id: String) -> Audience? { audiences.first { $0.id == id } }
    func plan(id: String) -> MarketingPlan? { plans.first { $0.id == id } }
    func plans(for audience: Audience) -> [MarketingPlan] {
        plans.filter { $0.audienceIDs.contains(audience.id) }
    }

    static let demo: MockDataStore = {
        let audience01 = Audience(
            id: "audience-01", number: 1, memberCount: 8_420, source: .ai, version: 1,
            scores: [
                AudienceScore(dimension: .spending, value: 4),
                AudienceScore(dimension: .frequency, value: 2),
                AudienceScore(dimension: .priceSensitivity, value: 1),
                AudienceScore(dimension: .newProducts, value: 5),
                AudienceScore(dimension: .classics, value: 2)
            ],
            categoryPreferences: [
                CategoryPreference(id: "category-a", name: "品类 A", percentage: 60),
                CategoryPreference(id: "category-b", name: "品类 B", percentage: 30),
                CategoryPreference(id: "category-other", name: "其他", percentage: 10)
            ])
        let audience02 = Audience(
            id: "audience-02", number: 2, memberCount: 3_160, source: .manual, version: 1,
            scores: [
                AudienceScore(dimension: .spending, value: 3),
                AudienceScore(dimension: .frequency, value: 4),
                AudienceScore(dimension: .priceSensitivity, value: 4),
                AudienceScore(dimension: .newProducts, value: 2),
                AudienceScore(dimension: .classics, value: 4)
            ],
            categoryPreferences: [
                CategoryPreference(id: "category-a", name: "品类 A", percentage: 40),
                CategoryPreference(id: "category-b", name: "品类 B", percentage: 50),
                CategoryPreference(id: "category-other", name: "其他", percentage: 10)
            ])
        let plans = [
            MarketingPlan(id: "plan-01", number: 1, purpose: .repurchase, customerStage: .purchased,
                          version: 1, message: "最近使用体验如何？为你准备了一份回购礼遇，欢迎了解适合你的补货选择。",
                          resourceSummary: "店铺已有优惠券 · 示例资源", source: .ai,
                          audienceIDs: ["audience-01", "audience-02"]),
            MarketingPlan(id: "plan-02", number: 2, purpose: .repurchase, customerStage: .purchased,
                          version: 1, message: "感谢你的支持。这里有一份产品关怀与回购推荐，希望继续为你提供合适的选择。",
                          resourceSummary: "店铺已有商品推荐 · 示例资源", source: .manual,
                          audienceIDs: ["audience-01"])
        ]
        guard let allocation = ABAllocation(groups: [
            .init(planID: "plan-01", planVersion: 1, percentage: 30),
            .init(planID: "plan-02", planVersion: 1, percentage: 70)
        ]) else { preconditionFailure("固定 A/B 示例数据不符合约定") }
        // 与当前待审批任务分开：数据页展示一个历史已发送批次的固定结果。
        let pending = ApprovalTask(id: "task-01", number: 1, audienceID: "audience-01",
                                   audienceVersion: 1, expectedReach: 2_000, allocation: allocation,
                                   approvalStatus: .pending, deliveryStatus: nil)
        let historical = ApprovalTask(id: "task-history-01", number: 2, audienceID: "audience-01",
                                      audienceVersion: 1, expectedReach: 2_000, allocation: allocation,
                                      approvalStatus: .confirmed, deliveryStatus: .succeeded)
        let analytics = AnalyticsSummary(
            id: "analytics-week-01",
            startDate: Date(timeIntervalSince1970: 1_791_129_600), // 2026/10/05 00:00 上海
            endDate: Date(timeIntervalSince1970: 1_791_734_399),   // 2026/10/11 23:59:59 上海
            audienceID: "audience-01", deliveryTaskID: historical.id,
            performances: [
                PlanPerformance(planID: "plan-01", planVersion: 1,
                                metrics: .init(reachedCustomers: 600, convertedCustomers: 36,
                                               orderCount: 42, revenueInCents: 630_000)),
                PlanPerformance(planID: "plan-02", planVersion: 1,
                                metrics: .init(reachedCustomers: 1_400, convertedCustomers: 132,
                                               orderCount: 154, revenueInCents: 2_310_000))
            ],
            totals: .init(reachedCustomers: 2_000, convertedCustomers: 168,
                          orderCount: 196, revenueInCents: 2_940_000))
        return MockDataStore(audiences: [audience01, audience02], plans: plans,
                             approvalTasks: [pending, historical], analytics: analytics)
    }()
}
