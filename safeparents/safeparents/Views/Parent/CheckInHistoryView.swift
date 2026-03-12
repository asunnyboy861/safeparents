import SwiftUI
import CoreData

struct CheckInHistoryView: View {
    @StateObject private var viewModel: CheckInHistoryViewModel
    @Environment(\.managedObjectContext) private var viewContext

    init(parent: Parent) {
        _viewModel = StateObject(wrappedValue: CheckInHistoryViewModel(parent: parent))
    }

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            if viewModel.checkIns.isEmpty {
                emptyStateView
            } else {
                checkInListView
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)

            Text("No Check-ins Yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primaryText)

            Text("Your check-in history will appear here")
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var checkInListView: some View {
        List {
            ForEach(viewModel.groupedCheckIns.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date)) {
                    ForEach(viewModel.groupedCheckIns[date] ?? [], id: \.objectID) { checkIn in
                        CheckInRowView(checkIn: checkIn)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct CheckInRowView: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryText)

                if let timestamp = checkIn.timestamp {
                    Text(timestamp.timeString)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()

            if let notes = checkIn.notes, !notes.isEmpty {
                Text(notes ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 24))
            .foregroundColor(iconColor)
            .frame(width: 40, height: 40)
            .background(iconColor.opacity(0.15))
            .clipShape(Circle())
    }

    private var iconName: String {
        let statusRaw = checkIn.status
        let status = CheckInStatus(rawValue: statusRaw) ?? .pending
        return status.iconName
    }

    private var iconColor: Color {
        let statusRaw = checkIn.status
        let status = CheckInStatus(rawValue: statusRaw) ?? .pending
        switch status {
        case .pending: return .secondaryText
        case .confirmed: return .safeGreen
        case .missed: return .alertRed
        case .custom: return .infoBlue
        }
    }

    private var statusText: String {
        let statusRaw = checkIn.status
        let status = CheckInStatus(rawValue: statusRaw) ?? .pending
        return status.displayName
    }
}

@MainActor
class CheckInHistoryViewModel: ObservableObject {
    @Published var checkIns: [CheckIn] = []
    @Published var groupedCheckIns: [String: [CheckIn]] = [:]

    private let checkInService: CheckInService
    private let parent: Parent

    init(parent: Parent, checkInService: CheckInService = .shared) {
        self.parent = parent
        self.checkInService = checkInService
        refresh()
    }

    func refresh() {
        checkIns = checkInService.fetchCheckIns(for: parent)
        groupCheckInsByDate()
    }

    private func groupCheckInsByDate() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        groupedCheckIns = Dictionary(grouping: checkIns) { checkIn in
            guard let timestamp = checkIn.timestamp else { return "Unknown" }
            return formatter.string(from: timestamp)
        }
    }
}
