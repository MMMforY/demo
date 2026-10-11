import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case audience, plan, approval, analytics

    var id: String { rawValue }
    var title: String {
        switch self {
        case .audience: "人群"
        case .plan: "方案"
        case .approval: "发送审批"
        case .analytics: "数据"
        }
    }
    var symbol: String {
        switch self {
        case .audience: "person.2"
        case .plan: "doc.text"
        case .approval: "paperplane"
        case .analytics: "chart.bar"
        }
    }
}
