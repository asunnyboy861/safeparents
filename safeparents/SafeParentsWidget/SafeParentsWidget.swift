import WidgetKit
import SwiftUI
import CoreData

struct CheckInEntry: TimelineEntry {
    let date: Date
    let parentName: String
    let status: CheckInStatus
    let lastCheckInTime: Date?
}

struct CheckInTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CheckInEntry {
        CheckInEntry(
            date: Date(),
            parentName: "Parent",
            status: .pending,
            lastCheckInTime: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CheckInEntry) -> Void) {
        let entry = loadCurrentStatus()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CheckInEntry>) -> Void) {
        let currentDate = Date()
        let entry = loadCurrentStatus()

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func loadCurrentStatus() -> CheckInEntry {
        let sharedDefaults = UserDefaults(suiteName: AppConstants.AppGroup.identifier)
        let parentName = sharedDefaults?.string(forKey: AppConstants.AppGroup.parentName) ?? "Parent"
        let statusRaw = sharedDefaults?.integer(forKey: AppConstants.AppGroup.checkInStatus) ?? 0
        let lastCheckInTimestamp = sharedDefaults?.double(forKey: AppConstants.AppGroup.lastCheckInTime)

        let status = CheckInStatus(rawValue: Int16(statusRaw)) ?? .pending
        let lastCheckInTime = lastCheckInTimestamp.map { Date(timeIntervalSince1970: $0) }

        return CheckInEntry(
            date: Date(),
            parentName: parentName,
            status: status,
            lastCheckInTime: lastCheckInTime
        )
    }
}

struct SafeParentsWidgetEntryView: View {
    var entry: CheckInEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: CheckInEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.status.iconName)
                .font(.system(size: 32))
                .foregroundColor(statusColor)

            Text(entry.parentName)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)

            if let lastCheckIn = entry.lastCheckInTime {
                Text(lastCheckIn.relativeString)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text("No check-in")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var statusColor: Color {
        switch entry.status {
        case .pending: return .orange
        case .confirmed: return .green
        case .missed: return .red
        case .custom: return .blue
        }
    }
}

struct MediumWidgetView: View {
    let entry: CheckInEntry

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: entry.status.iconName)
                .font(.system(size: 40))
                .foregroundColor(statusColor)
                .frame(width: 60, height: 60)
                .background(statusColor.opacity(0.15))
                .cornerRadius(30)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.parentName)
                    .font(.system(size: 16, weight: .semibold))

                Text(statusText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                if let lastCheckIn = entry.lastCheckInTime {
                    Text("Last check-in: \(lastCheckIn.relativeString)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var statusColor: Color {
        switch entry.status {
        case .pending: return .orange
        case .confirmed: return .green
        case .missed: return .red
        case .custom: return .blue
        }
    }

    private var statusText: String {
        switch entry.status {
        case .pending: return "Waiting for check-in"
        case .confirmed: return "All good! ✓"
        case .missed: return "Check-in missed"
        case .custom: return "Custom status"
        }
    }
}

@main
struct SafeParentsWidget: Widget {
    let kind: String = "SafeParentsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CheckInTimelineProvider()) { entry in
            SafeParentsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SafeParents")
        .description("See your family's check-in status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SafeParentsWidget()
} timeline: {
    CheckInEntry(date: .now, parentName: "Dad", status: .confirmed, lastCheckInTime: Date())
    CheckInEntry(date: .now, parentName: "Mom", status: .pending, lastCheckInTime: nil)
}

#Preview(as: .systemMedium) {
    SafeParentsWidget()
} timeline: {
    CheckInEntry(date: .now, parentName: "Dad", status: .confirmed, lastCheckInTime: Date())
}
