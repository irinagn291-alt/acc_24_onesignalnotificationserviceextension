import Combine
import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case history
    case favorites
    case dayLists
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .history: "History"
        case .favorites: "Favorites"
        case .dayLists: "Days"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .history: "clock.fill"
        case .favorites: "heart.fill"
        case .dayLists: "calendar"
        case .settings: "gearshape.fill"
        }
    }
}

enum HomeRoute: Hashable {
    case product(String)
    case search(String)
}

enum DayListsRoute: Hashable {
    case day(Date)
    case product(String)
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var homePath = NavigationPath()
    @Published var historyPath = NavigationPath()
    @Published var favoritesPath = NavigationPath()
    @Published var dayListsPath = NavigationPath()

    @Published var isScannerPresented = false

    func openProductFromHome(barcode: String) {
        selectedTab = .home
        var p = homePath
        p.append(HomeRoute.product(barcode))
        homePath = p
    }

    func openSearchFromHome(query: String) {
        selectedTab = .home
        var p = homePath
        p.append(HomeRoute.search(query))
        homePath = p
    }

    func openProductFromHistory(barcode: String) {
        var p = historyPath
        p.append(barcode)
        historyPath = p
    }

    func openProductFromFavorites(barcode: String) {
        var p = favoritesPath
        p.append(barcode)
        favoritesPath = p
    }

    func openProductFromDayLists(barcode: String) {
        selectedTab = .dayLists
        var p = dayListsPath
        p.append(DayListsRoute.product(barcode))
        dayListsPath = p
    }

    func dismissScannerIfNeeded() {
        isScannerPresented = false
    }
}
