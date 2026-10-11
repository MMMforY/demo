import Foundation

struct AnalyticsSummary: Identifiable, Hashable {
    let id: String
    let startDate: Date
    let endDate: Date
    let audienceID: String
    /// 引用历史已发送批次，不是当前待审批任务。
    let deliveryTaskID: String
    let performances: [PlanPerformance]
    /// 独立存储经过去重的合计，避免未来跨任务直接累加客户数。
    let totals: MarketingMetrics
}

struct PlanPerformance: Identifiable, Hashable {
    let planID: String
    let planVersion: Int
    let metrics: MarketingMetrics
    var id: String { planID }
}

struct MarketingMetrics: Hashable {
    let reachedCustomers: Int
    let convertedCustomers: Int
    let orderCount: Int
    /// 人民币分，避免金额二进制浮点误差。
    let revenueInCents: Int

    var conversionRate: Double? {
        guard reachedCustomers > 0 else { return nil }
        return Double(convertedCustomers) / Double(reachedCustomers)
    }
}
