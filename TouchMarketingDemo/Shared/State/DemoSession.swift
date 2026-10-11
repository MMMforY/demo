import Foundation
import Observation

@Observable
final class DemoSession {
    private let seed: MockDataStore
    private(set) var audienceSnapshots: [AudienceSnapshot] = []
    private(set) var plans: [MarketingPlan] = []
    private(set) var approvalTasks: [ApprovalTask] = []
    private(set) var analytics: AnalyticsSummary
    private(set) var fields: [AudienceField] = []
    private(set) var versions: [VersionRecord] = []
    private(set) var suggestions: [DemoSuggestion] = []
    private(set) var resetGeneration = 0
    private var nextAudienceNumber = 1

    init(store: MockDataStore = .demo) {
        seed = store
        analytics = store.analytics
        restoreSeed()
    }
    var audiences: [Audience] { audienceSnapshots.map(\.audience) }
    var store: MockDataStore { .init(audiences: audiences, plans: plans, approvalTasks: approvalTasks, analytics: analytics) }
    /// The existing read-only approval UI must display the referenced profile, never current V2 as V1.
    var approvalStore: MockDataStore {
        let frozen = audiences.map { current in
            guard let task = approvalTasks.first(where: { $0.audienceID == current.id }),
                  let snapshot = audienceVersion(id: current.id, version: task.audienceVersion) else { return current }
            return snapshot.audience
        }
        return .init(audiences: frozen, plans: plans, approvalTasks: approvalTasks, analytics: analytics)
    }
    func audience(id: String) -> AudienceSnapshot? { audienceSnapshots.first { $0.audience.id == id } }
    func audienceVersion(id: String, version: Int) -> AudienceSnapshot? {
        guard let record = versions.first(where: { $0.objectKind == .audience && $0.objectID == id && $0.version == version }),
              case .audience(let snapshot) = record.content else { return nil }
        return snapshot
    }
    func planVersion(id: String, version: Int) -> MarketingPlan? {
        guard let record = versions.first(where: { $0.objectKind == .plan && $0.objectID == id && $0.version == version }),
              case .plan(let plan) = record.content else { return nil }
        return plan
    }
    func history(kind: VersionObjectKind, id: String) -> [VersionRecord] {
        versions.filter { $0.objectKind == kind && $0.objectID == id }.sorted { $0.version > $1.version }
    }
    func coverage(for selection: [Audience]) -> Int? {
        if selection.isEmpty { return 0 }
        let snapshots = selection.compactMap { audience(id: $0.id) }
        guard snapshots.count == selection.count,
              snapshots.allSatisfy({ $0.recognition == .ready || $0.recognition == .empty }) else { return nil }
        if selection.count == 1 { return selection[0].memberCount }
        if Set(selection.map(\.id)) == Set(["audience-01", "audience-02"]),
           selection.allSatisfy({ current in MockDataStore.demo.audience(id: current.id) == current }) {
            return MockDataStore.audienceUnionCoverage
        }
        return nil
    }
    func reset() { restoreSeed(); resetGeneration += 1 }
    private func restoreSeed() {
        plans = seed.plans; approvalTasks = seed.approvalTasks; analytics = seed.analytics
        fields = MockDataStore.audienceFields
        suggestions = MockDataStore.audienceSuggestions.filter { suggestion in seed.audience(id: suggestion.targetID) != nil }
        audienceSnapshots = seed.audiences.map {
            .init(audience: $0, rules: MockDataStore.audienceRules(number: $0.number), recognition: .ready, metadata: .demo)
        }
        versions = audienceSnapshots.map { versionRecord($0, source: .seed, summary: "初始规则及画像固定样本", at: DemoClock.referenceDate) }
        versions += plans.map {
            .init(id: "plan:\($0.id):\($0.version)", objectKind: .plan, objectID: $0.id, version: $0.version,
                  createdAt: DemoClock.referenceDate, changeSource: .seed, summary: "初始方案固定样本", content: .plan($0))
        }
        nextAudienceNumber = (seed.audiences.map(\.number).max() ?? 0) + 1
    }
    private func versionRecord(_ snapshot: AudienceSnapshot, source: VersionChangeSource, summary: String, at: Date) -> VersionRecord {
        .init(id: "audience:\(snapshot.audience.id):\(snapshot.audience.version)", objectKind: .audience,
              objectID: snapshot.audience.id, version: snapshot.audience.version, createdAt: at,
              changeSource: source, summary: summary, content: .audience(snapshot))
    }
    private func validate(_ rules: AudienceRules, existing: AudienceRules?) throws {
        guard !rules.conditions.isEmpty else { throw DemoValidationError(message: "至少添加一条有效条件。") }
        guard Set(rules.conditions.map(\.id)).count == rules.conditions.count else { throw DemoValidationError(message: "条件 ID 重复，请重新添加条件。") }
        guard Set(rules.conditions.map { $0.field.id }).count == rules.conditions.count else { throw DemoValidationError(message: "同一字段有重复或冲突条件，请合并为一个区间。") }
        for condition in rules.conditions {
            guard let current = fields.first(where: { $0.id == condition.field.id }) else { throw DemoValidationError(message: "字段已不可用。") }
            // An unchanged existing condition can retain its frozen field definition, even if disabled.
            if existing?.conditions.contains(condition) == true { continue }
            guard current.isEnabled else { throw DemoValidationError(message: "\(current.name)已停用，不能用于新条件。") }
            guard condition.field == current else { throw DemoValidationError(message: "\(current.name)定义已更新，请重新选择字段。") }
            guard AudienceRuleOperator.allowed(for: current.type).contains(condition.operation) else { throw DemoValidationError(message: "\(current.name)的判断方式与字段类型不匹配。") }
            switch (current.type, condition.value) {
            case (.number, .number(let value)):
                guard value.isFinite, value >= 0, condition.operation != .between else { throw DemoValidationError(message: "请输入有效的非负数字；区间需要上下限。") }
            case (.number, .range(let lower, let upper)):
                guard condition.operation == .between, lower.isFinite, upper.isFinite, lower >= 0, lower <= upper else { throw DemoValidationError(message: "区间下限不能大于上限，且必须是有效非负数字。") }
            case (.category, .category(let value)):
                guard current.options.contains(value), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DemoValidationError(message: "请选择有效分类属性值。") }
            case (.date, .date(let date)):
                guard date.timeIntervalSince1970.isFinite else { throw DemoValidationError(message: "日期无效。") }
            case (.boolean, .boolean): break
            default: throw DemoValidationError(message: "\(current.name)的属性值与字段类型不匹配。")
            }
        }
    }
    @discardableResult
    func saveAudience(id: String?, baseVersion: Int?, rules: AudienceRules, source: VersionChangeSource = .manualEdit) throws -> AudienceSnapshot {
        let existing = id.flatMap { audience(id: $0) }
        if id != nil && existing == nil { throw DemoValidationError(message: "人群不存在，请返回列表。") }
        if let existing, existing.audience.version != baseVersion { throw DemoValidationError(message: "人群版本已变化，请重新打开编辑。") }
        var clean = rules
        clean.instruction = rules.instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate(clean, existing: existing?.rules)
        if let existing, existing.rules == clean { return existing }
        let number = existing?.audience.number ?? nextAudienceNumber
        let new = Audience(id: existing?.audience.id ?? UUID().uuidString, number: number, memberCount: 0,
                           source: existing?.audience.source ?? .manual, version: (existing?.audience.version ?? 0) + 1,
                           scores: AudienceScore.Dimension.allCases.map { .init(dimension: $0, value: nil) }, categoryPreferences: [])
        var metadata = AudienceProfileMetadata.demo
        metadata.updatedAt = Date()
        let snapshot = AudienceSnapshot(audience: new, rules: clean, recognition: .recognizing, metadata: metadata)
        if let index = audienceSnapshots.firstIndex(where: { $0.audience.id == new.id }) { audienceSnapshots[index] = snapshot }
        else { audienceSnapshots.append(snapshot); nextAudienceNumber += 1 }
        let summary: String
        if let existing {
            summary = "\(existing.rules.conditions.map(\.summary).joined(separator: "；")) → \(clean.conditions.map(\.summary).joined(separator: "；"))；\(clean.relation.rawValue)；说明\(existing.rules.instruction == clean.instruction ? "未变" : "已更新")"
        } else { summary = "创建规则：\(clean.conditions.map(\.summary).joined(separator: "；"))" }
        versions.append(versionRecord(snapshot, source: source, summary: summary, at: Date()))
        return snapshot
    }
    func completeRecognition(id: String, version: Int, scenario: AudienceRecognition) throws {
        guard scenario != .recognizing,
              let index = audienceSnapshots.firstIndex(where: { $0.audience.id == id }),
              audienceSnapshots[index].audience.version == version else { throw DemoValidationError(message: "人群版本已变化或识别场景无效。") }
        var snapshot = audienceSnapshots[index]
        // Each version completes once; a refresh doesn't rewrite already frozen historical results.
        guard snapshot.recognition == .recognizing else { throw DemoValidationError(message: "本版本模拟识别已完成，请编辑规则后再选择场景。") }
        guard let template = seed.audiences.first else { throw DemoValidationError(message: "没有可用的模拟画像样本。") }
        let old = snapshot.audience
        snapshot.audience = Audience(id: old.id, number: old.number, memberCount: scenario == .ready ? template.memberCount : 0,
                                     source: old.source, version: old.version,
                                     scores: scenario == .ready ? template.scores : AudienceScore.Dimension.allCases.map { .init(dimension: $0, value: nil) },
                                     categoryPreferences: scenario == .ready ? template.categoryPreferences : [])
        snapshot.recognition = scenario; snapshot.metadata.updatedAt = Date()
        audienceSnapshots[index] = snapshot
        if let record = versions.firstIndex(where: { $0.objectKind == .audience && $0.objectID == id && $0.version == version }) {
            versions[record].content = .audience(snapshot)
        }
    }
    @discardableResult
    func saveField(_ draft: AudienceField) throws -> AudienceField {
        let existing = fields.first { $0.id == draft.id }
        if let existing, existing.version != draft.version { throw DemoValidationError(message: "字段版本已变化，请重新打开编辑。") }
        guard !draft.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              draft.isBuiltIn == (existing?.isBuiltIn ?? false) else { throw DemoValidationError(message: "字段标识或内置属性无效。") }
        var clean = draft
        clean.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.explanation = draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.evidence = draft.evidence.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.options = draft.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !clean.name.isEmpty, !clean.explanation.isEmpty, !clean.evidence.isEmpty else { throw DemoValidationError(message: "字段名称、说明和识别依据不能为空。") }
        guard !fields.contains(where: { $0.id != clean.id && $0.name.caseInsensitiveCompare(clean.name) == .orderedSame }) else { throw DemoValidationError(message: "字段名称重复，请使用不同名称。") }
        if clean.type == .category {
            guard !clean.options.isEmpty, clean.options.allSatisfy({ !$0.isEmpty }), Set(clean.options.map { $0.lowercased() }).count == clean.options.count else { throw DemoValidationError(message: "分类属性值不能为空或重复，至少保留一个。") }
        } else { clean.options = [] }
        if let existing, existing.isBuiltIn {
            guard clean.name == existing.name, clean.type == existing.type, clean.explanation == existing.explanation, clean.options == existing.options, clean.evidence == existing.evidence else { throw DemoValidationError(message: "内置字段语义不可修改。") }
        }
        if existing == clean { return clean }
        clean.version = (existing?.version ?? 0) + 1
        if let index = fields.firstIndex(where: { $0.id == clean.id }) { fields[index] = clean } else { fields.append(clean) }
        return clean
    }
    @discardableResult
    func adoptSuggestion(id: String) throws -> AudienceSnapshot {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { throw DemoValidationError(message: "建议不存在。") }
        let suggestion = suggestions[index]
        guard suggestion.status == .pending || suggestion.status == .deferred else { throw DemoValidationError(message: "该建议已采纳或已失效，不能重复采纳。") }
        guard suggestion.targetKind == .audience, let current = audience(id: suggestion.targetID), current.audience.version == suggestion.baseVersion else { throw DemoValidationError(message: "建议基于旧版本，请重新核对，不能覆盖最新版。") }
        guard let rules = suggestion.proposedRules, rules != current.rules else { throw DemoValidationError(message: "建议没有可保存的规则变更。") }
        let result = try saveAudience(id: suggestion.targetID, baseVersion: suggestion.baseVersion, rules: rules, source: .aiAdoption)
        suggestions[index].status = .adopted; suggestions[index].generatedVersion = result.audience.version; suggestions[index].processedAt = Date()
        return result
    }
    func deferSuggestion(id: String) throws {
        guard let index = suggestions.firstIndex(where: { $0.id == id }), suggestions[index].status == .pending else { throw DemoValidationError(message: "只有待处理建议可以暂不采纳。") }
        suggestions[index].status = .deferred; suggestions[index].processedAt = Date()
    }
    /// B's minimal write contract; feature-specific resource validation belongs to B's future integration.
    func savePlan(_ plan: MarketingPlan, baseVersion: Int) throws {
        guard let index = plans.firstIndex(where: { $0.id == plan.id }), plans[index].version == baseVersion,
              plan.number == plans[index].number, plan.version == baseVersion + 1,
              !plan.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              plan.audienceIDs.allSatisfy({ audience(id: $0) != nil }) else { throw DemoValidationError(message: "方案版本、编号、话术或人群引用无效。") }
        plans[index] = plan
        versions.append(.init(id: "plan:\(plan.id):\(plan.version)", objectKind: .plan, objectID: plan.id, version: plan.version,
                              createdAt: Date(), changeSource: .manualEdit, summary: "方案内容保存", content: .plan(plan)))
    }
    /// C's draft-only write contract. Confirmed/history tasks cannot be rewritten through this method.
    func updatePendingTask(_ task: ApprovalTask) throws {
        guard let index = approvalTasks.firstIndex(where: { $0.id == task.id }),
              [.pending, .deferred].contains(approvalTasks[index].approvalStatus),
              [.pending, .deferred, .rejected].contains(task.approvalStatus), task.deliveryStatus == nil,
              task.number == approvalTasks[index].number, task.expectedReach >= 0,
              let snapshot = audienceVersion(id: task.audienceID, version: task.audienceVersion),
              snapshot.recognition == .ready, task.expectedReach <= snapshot.audience.memberCount,
              task.allocation.groups.allSatisfy({ planVersion(id: $0.planID, version: $0.planVersion) != nil }) else { throw DemoValidationError(message: "任务状态、版本引用或覆盖人数无效。") }
        approvalTasks[index] = task
    }
}
