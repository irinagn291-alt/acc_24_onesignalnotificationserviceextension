import Alamofire
import OneSignalFramework
import SwiftUI

@main
struct app_268App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var env = AppEnvironment()
    @State private var isInitializing = true
    @State private var displayMode: DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(env)
                .onAppear(perform: performRegistration)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if displayMode == .webContent, let url = webContentURL {
                WebContentShell(urlString: url)
            } else {
                RootView(env: env)
                    .preferredColorScheme(.light)
                    .task {
                        await env.bootstrap()
                    }
            }
        }
    }

    private func performRegistration() {
        let pushToken = OneSignal.User.pushSubscription.token ?? ""
        NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async {
                displayMode = mode
                webContentURL = url
                isInitializing = false
            }
        }
    }
}

private struct WebContentShell: View {
    let urlString: String

    private var fullURL: String {
        urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            WebContentView(url: fullURL)
        }
        .preferredColorScheme(.dark)
    }
}
