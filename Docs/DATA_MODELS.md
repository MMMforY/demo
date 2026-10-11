# 数据模型与约定

> B 分支增补（2026/10/11）：方案领域类型、校验和只读样本已写入独立新文件；共享会话与任务生成仍待 A/C 整合。下文为原骨架模型基线，新增字段、所有权和迁移说明见 [B 对接说明](DeveloperTasks/B_PLAN_INTEGRATION.md)。新增 PlanVersionSnapshot 是方案内容快照，不另建通用 VersionRecord；PlanMetadata 暂按 plan ID 保存资源引用及时间，不改变既有 MarketingPlan 初始化参数。

模型位于 `TouchMarketingDemo/Shared/Models`，统一 fixture 位于 `Shared/MockData/MockDataStore.swift`。类型为轻量值对象，不对应网络响应或数据库表。稳定字符串 ID 用于关联，编号单独存储，不能由数组下标生成。

## 已写入 Swift 的对象

| 类型 | 主要字段及说明 |
| --- | --- |
| `Audience` | `id`、`number`、`memberCount`、`source`、`version`、`scores`、`categoryPreferences`；`displayName` 如人群 01 |
| `AudienceScore` | `dimension`、`value: Int?`；五维枚举，1...5，nil 为依据不足；`displayValue` |
| `CategoryPreference` | `id`、`name`、`percentage`（0...100）；当前按购买件数展示固定示例 |
| `MarketingPlan` | `id`、`number`、`purpose`、`customerStage`、`version`、`message`、`resourceSummary`、`source`、`audienceIDs`；`displayName` 如方案 01 |
| `ApprovalTask` | `id`、`number`、`audienceID`、`audienceVersion`、`expectedReach`、`allocation`、`approvalStatus`、`deliveryStatus: DeliveryStatus?` |
| `ABAllocation` | `groups` 包含一或两个 `Group`；每组 `planID`、`planVersion`、`percentage`；组 ID 是方案 ID |
| `AnalyticsSummary` | `id`、`startDate`、`endDate`、`audienceID`、`deliveryTaskID`、`performances`、`totals` |
| `PlanPerformance` | `planID`、`planVersion`、`metrics`；当前每个摘要同一方案只一条，不支持重复版本混合条目 |
| `MarketingMetrics` | `reachedCustomers`、`convertedCustomers`、`orderCount`、`revenueInCents`；`conversionRate: Double?` 为计算属性 |

金额使用人民币分的整数，界面转人民币元；百分比分配和品类使用 0...100 整数；转化率使用 0...1 比值，由格式化层显示百分数。计数不得为负；画像 1...5 与品类占比由 fixture 作者遵守，本轮不为所有模型增加表单校验层。

## 已实现的枚举

| 枚举 | 值 |
| --- | --- |
| `CreationSource` | `ai`（AI 创建）、`manual`（手动创建） |
| `AudienceScore.Dimension` | `spending` 消费水平、`frequency` 购买频次、`priceSensitivity` 价格敏感度、`newProducts` 新品偏好、`classics` 经典款偏好 |
| `PlanPurpose` | `nurture` 新客培育、`firstPurchase` 首购转化、`repurchase` 复购促进、`valueGrowth` 价值提升、`relationship` 关系维护、`winBack` 流失召回 |
| `CustomerStage` | `newContact`、`beforeFirstPurchase`、`purchased`、`repeatBuyer`、`lowActivity`、`longInactive`、`any` |
| `ApprovalStatus` | `pending` 待审批、`deferred` 稍后处理、`confirmed` 已确认、`rejected` 已拒绝 |
| `DeliveryStatus` | `waiting` 等待发送、`sending` 发送中、`succeeded` 发送成功、`partiallyFailed` 部分失败、`failed` 发送失败 |

未审批的任务执行状态为 nil。“已发送”是业务列表分组，后续可包含已确认但等待发送的任务，不等于执行成功。

## 关系与稳定 ID

- 人群：`audience-01`、`audience-02`；方案：`plan-01`、`plan-02`。
- `MarketingPlan.audienceIDs` 是人群—方案多对多关系的唯一来源。方案 01 关联两个人群，方案 02 关联人群 01；通过 `store.plans(for:)` 得到反向关系，禁止再维护 Audience.planIDs 导致不一致。
- 待审批 `task-01`（任务 01）引用人群 01 V1 和方案 01／02 V1。
- 历史 `task-history-01`（任务 02）已确认、发送成功，供 `analytics-week-01` 统计引用。历史与待审批使用相同配置作为示例，统计不是待审批任务的未来结果。
- 任务版本引用可追溯；当前 store 只有 V1 对象，没有完整冻结内容。真实的历史详情和任务快照需后续补充，不能直接用最新内容代替旧版本。
- `MockDataStore.audience(id:)`／`plan(id:)` 可返回 nil；页面展示不可用说明。维护 fixture 时须确保所有引用有效。

## A/B 规则

`ABAllocation.init?(groups:)` 校验：一到两个组、方案 ID 不为空且不同、版本为正、比例为正整数、总和 100%。因此单方案只能 100%，双方案各为 1...99%；0% 不构成双组测试。添加第三套方案或重复方案返回 nil。

`expectedCounts(total:)` 单方案返回全量；双方案 A 向下取整，B 取余，人数合计等于任务人数。当前示例 2,000 → 600／1,400。它只是 Demo 的预计人数约定；小样本空组、真实客户去重和分配不在本阶段实现。表单将来应处理 nil 并展示提示，不将固定 fixture 的断言当作用户输入校验。

## 数据口径

固定区间为上海时区 2026/10/05 00:00 至 2026/10/11 23:59:59，时间戳写入 fixture，不依赖设备当天日期。没有时间范围枚举或日期筛选行为。

| 指标 | 方案 01 | 方案 02 | 合计 |
| --- | ---: | ---: | ---: |
| 触达人数 | 600 | 1,400 | 2,000 |
| 成交人数 | 36 | 132 | 168 |
| 订单数 | 42 | 154 | 196 |
| 金额（元） | 6,300 | 23,100 | 29,400 |
| 转化率 | 6.00% | 9.43% | 8.40% |

转化率 = 成交人数 ÷ 触达人数，分母 0 时返回 nil，显示“—”。合计存储在 `totals`，不可对两个百分率取平均。当前互斥同组示例可相加，未来跨任务合计需要去重；本 App 不持有客户名单，不能声称已经执行去重。

## 仅文档约定，尚未写入 Swift

`VersionRecord`：后续最小字段建议为稳定 `id`、`objectKind`（audience／plan）、`objectID`、`version`、`createdAt`、`changeSource`（manualEdit／aiAdoption）、`summary`。真正实现历史详情时，再定义人群规则／方案内容的类型化快照，不提前加入任意 JSON 或空协议。

本阶段所有人群和方案只有当前 `version`，没有 VersionRecord 数组或历史 UI。暂不实现观察周期、规则条件、自定义字段、量表版本、更新日期、建议处理记录、资源对象、触达规则、处理记录、失败客户范围、执行快照、统计完成状态和趋势点。

后续规则：发送快照需冻结人群／方案版本和分配；数据需补 `audienceVersion`、批次及归因范围；统计中的未知值须显式表示，不作为 0。多个方案版本合并统计时，应调整 PlanPerformance 的唯一 ID 与分组约定。扩展共享模型必须同时更新本文件、fixture 和相关页面。
