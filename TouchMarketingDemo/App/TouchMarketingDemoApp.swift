import SwiftUI

@main
struct TouchMarketingDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.light)
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }
}
