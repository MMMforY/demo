import Foundation

struct ApprovalTask: Identifiable, Hashable {
    let id: String
    let number: Int
    let audienceID: String
    let audienceVersion: Int
    let expectedReach: Int
    let allocation: ABAllocation
    let approvalStatus: ApprovalStatus
    /// 待审批任务为 nil；审批状态与执行状态不能混用。
    let deliveryStatus: DeliveryStatus?

    var displayName: String { DemoFormat.numbered("任务", number) }
}

enum ApprovalStatus: String, CaseIterable {
    case pending = "待审批"
    case deferred = "稍后处理"
    case confirmed = "已确认"
    case rejected = "已拒绝"
}

enum DeliveryStatus: String, CaseIterable {
    case waiting = "等待发送"
    case sending = "发送中"
    case succeeded = "发送成功"
    case partiallyFailed = "部分失败"
    case failed = "发送失败"
}

struct ABAllocation: Hashable {
    struct Group: Identifiable, Hashable {
        let planID: String
        let planVersion: Int
        let percentage: Int
        var id: String { planID }
    }
    let groups: [Group]

    /// 单方案 100%；双方案各占 1...99%，不同方案、总和 100%。
    init?(groups: [Group]) {
        guard (1...2).contains(groups.count),
              Set(groups.map(\.planID)).count == groups.count,
              groups.allSatisfy({ !$0.planID.isEmpty && $0.planVersion > 0 && (1...100).contains($0.percentage) }),
              groups.reduce(0, { $0 + $1.percentage }) == 100 else { return nil }
        self.groups = groups
    }

    /// 最后一组取余数，确保两组人数相加等于任务人数。
    func expectedCounts(total: Int) -> [Int] {
        guard total >= 0 else { return [] }
        if groups.count == 1 { return [total] }
        let first = Int((Double(total) * Double(groups[0].percentage) / 100).rounded(.down))
        return [first, total - first]
    }
}
