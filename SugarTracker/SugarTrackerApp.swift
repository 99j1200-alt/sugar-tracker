import SwiftUI

@main
struct SugarTrackerApp: App {
    @StateObject private var store = ReadingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ReadingsView()
                .tabItem { Label("القراءات", systemImage: "list.bullet.rectangle") }
            StatsView()
                .tabItem { Label("الإحصائيات", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("الإعدادات", systemImage: "gearshape") }
        }
        .tint(.teal)
    }
}
