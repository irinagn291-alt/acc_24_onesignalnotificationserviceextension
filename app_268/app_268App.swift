import SwiftUI

@main
struct app_268App: App {
    @StateObject private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
                .environmentObject(env)
                .preferredColorScheme(.light)
                .task {
                    await env.bootstrap()
                }
        }
    }
}
