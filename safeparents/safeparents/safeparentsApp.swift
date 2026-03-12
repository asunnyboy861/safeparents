import SwiftUI
import BackgroundTasks

@main
struct SafeParentsApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared

    init() {
        BackgroundTaskService.shared.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .onAppear {
                    scheduleNextBackgroundTask()
                }
        }
    }

    private func scheduleNextBackgroundTask() {
        BackgroundTaskService.shared.scheduleBackgroundTask()
    }
}
