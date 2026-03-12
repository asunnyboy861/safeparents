import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
    @State private var selectedTab: Int = 0
    @State private var currentParent: Parent?
    @State private var userRole: UserRole = .parent

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
                    .onChange(of: showOnboarding) { _, newValue in
                        if !newValue {
                            loadCurrentParent()
                        }
                    }
            } else if let parent = currentParent {
                if userRole == .parent {
                    parentTabView(parent: parent)
                } else {
                    childTabView(parent: parent)
                }
            } else {
                ProgressView()
                    .onAppear {
                        loadCurrentParent()
                    }
            }
        }
    }

    private func loadCurrentParent() {
        let request: NSFetchRequest<Parent> = Parent.fetchRequest()
        request.fetchLimit = 1

        do {
            if let parent = try viewContext.fetch(request).first {
                currentParent = parent
                userRole = UserRole(rawValue: parent.role ?? "parent") ?? .parent
            }
        } catch {
            print("Error loading parent: \(error)")
        }
    }

    private func parentTabView(parent: Parent) -> some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ParentCheckInView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                CheckInHistoryView(parent: parent)
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(1)

            NavigationStack {
                ScheduleSetupView(parent: parent)
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(.infoBlue)
        .onAppear {
            setupTabBarAppearance()
        }
    }

    private func childTabView(parent: Parent) -> some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChildDashboardView(currentParent: parent)
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                FamilyManagementView()
            }
            .tabItem {
                Label("Family", systemImage: "person.3.fill")
            }
            .tag(1)

            NavigationStack {
                ScheduleSetupView(parent: parent)
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .tint(.infoBlue)
        .onAppear {
            setupTabBarAppearance()
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
