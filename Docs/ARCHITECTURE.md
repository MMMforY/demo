# 整体架构

## 实际目录

```text
demo/
├── TouchMarketingDemo.xcodeproj/  工程与共享 Scheme
├── TouchMarketingDemo/
│   ├── App/                     入口、Tab 定义与统一注册
│   ├── Features/
│   │   ├── Audience/            AudienceHomeView、AudienceDetailView
│   │   ├── Plan/                PlanHomeView、PlanDetailView
│   │   ├── Approval/            ApprovalHomeView、ApprovalDetailView
│   │   └── Analytics/           AnalyticsHomeView、AnalyticsDetailView
│   ├── Shared/
│   │   ├── Models/              人群、方案、任务、分配、统计
│   │   ├── MockData/            MockDataStore
│   │   ├── Components/          页面、卡片、值行、按钮样式、空状态
│   │   ├── DesignSystem/        DemoTheme
│   │   └── Utilities/           DemoFormat
│   ├── Resources/Info.plist     应用名称、中文、竖屏、浅色
│   └── Assets.xcassets/         黑色 AccentColor
├── Docs/                        协作与范围文档、产品副本和DeveloperTasks
├── .gitignore
└── README.md
```

没有空的 Navigation 目录：现阶段系统导航已足够，未来确有跨模块路由需求再补充。没有额外工具、依赖生成文件或包管理文件。

## 启动与导航

`TouchMarketingDemoApp` → `AppRootView` → `TabView(selection:)` → 每个 Tab 独立 `NavigationStack` → 模块首页 → 模块详情。

`AppTab` 统一维护顺序、标签和系统图标；`AppRootView.moduleHome(for:)` 是唯一模块注册处。选择状态为局部 `@State`，默认人群。首页用真实 `NavigationLink`，详情由系统提供返回导航并保留底部 Tab，还提供 `dismiss()` 返回按钮。不使用手工导航栏或全局路由器，不增加自定义动画。

每个模块拥有自己的导航栈，不能在 Feature 中再包一个根级导航栈或重建 TabView。后续复杂页面若需要类型化路径，优先定义模块内的 Route。

## Feature 与 Shared

Feature 只包含该业务的 View 和以后确实需要的局部状态。不同 Feature 不导入或实例化彼此的具体 View。共享模型、fixture、展示组件、样式与格式化只放 Shared。

工程是一个 App Target，目录构成轻量协作边界，不是四个独立 Swift Package。无需协议仓库、Service 层、依赖注入容器或多个 Target。

## 模拟数据流

`AppRootView` 保存 `MockDataStore.demo` 的只读引用值并传入四个首页。首页遍历统一数组，进入详情时传入对象及同一个 store；详情用稳定 ID 查询相关对象。静态只读 store 无网络、数据库、计时器、文件读写或跨模块状态同步。

方案关联人群以 `MarketingPlan.audienceIDs` 为唯一来源，人群详情反向过滤。任务引用人群／方案 ID 和版本，统计引用历史已发送任务 ID 和方案版本。当前待审批任务与历史统计分开，不能把统计当作待审批任务的执行结果。

若后续要做审批调整和模拟发送，可将确实共享的可变数据迁入一个 `@Observable` 容器，在 App 根注入；表单草稿保留模块内 `@State`。先协商 Shared 的接口和状态流程，不为当前只读数据预建框架。

## 工程文件与合并

Xcode 16+ `PBXFileSystemSynchronizedRootGroup` 同步 `TouchMarketingDemo` 目录。新增目录内 `.swift` 自动加入 Target，避免每人同时修改 `project.pbxproj`。`Resources/Info.plist` 通过同步例外排除复制资源，由 `INFOPLIST_FILE` 构建设置处理。共享 Scheme 可在另一台机器直接运行。

## 省略的能力

只搭建展示与点击骨架。省略网络、真实 API、AI、数据库、鉴权、埋点、错误监控、发送队列、后台任务、生产级去重／归因算法、版本快照持久化，以及覆盖率体系。静态模型中的版本引用为后续演示提供约定，不代表已实现完整快照系统。

## 开发准备状态

四人下一阶段实施计划见 DeveloperTasks；其中DemoSession、扩展资源/规则/版本/建议/批次/统计类型尚未写入Swift。当前实现仍是上文的只读store。未来接线由A先集中完成最小基础，再由四模块分别补业务；本文的“实际目录”不预先列入计划文件。
