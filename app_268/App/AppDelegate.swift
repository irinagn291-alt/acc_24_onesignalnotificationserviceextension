import Alamofire
import AppTrackingTransparency
import AppsFlyerLib
import OneSignalFramework
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppConfiguration.serverBaseURL = "https://fooduch-zephyr.com"

        AppsFlyerLib.shared().appsFlyerDevKey = "FtNRvpMYwiZh75MRTspiV8"
        AppsFlyerLib.shared().appleAppID = "6766458937"
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

        OneSignal.initialize("ef0409e7-9c3a-457c-b111-17143db36de4", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: false)

        application.registerForRemoteNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    @objc private func applicationDidBecomeActive() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                AppsFlyerLib.shared().start()
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}
