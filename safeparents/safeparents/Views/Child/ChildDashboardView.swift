import SwiftUI
import CoreData

struct ChildDashboardView: View {
    let currentParent: Parent
    @StateObject private var viewModel: ChildDashboardViewModel
    @Environment(\.managedObjectContext) private var viewContext

    init(currentParent: Parent) {
        self.currentParent = currentParent
        _viewModel = StateObject(wrappedValue: ChildDashboardViewModel(parent: currentParent))
    }

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    if viewModel.familyMembers.isEmpty {
                        emptyStateView
                    } else {
                        familyMembersList
                    }
                }
                .padding()
            }
            .refreshable {
                viewModel.refresh()
            }
        }
        .navigationTitle("Family Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(Date().timeOfDay())!")
                        .font(.system(size: AppConstants.UI.headlineFontSize, weight: .medium))
                        .foregroundColor(.primaryText)

                    Text("Your Family Status")
                        .font(.system(size: AppConstants.UI.bodyFontSize))
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                Circle()
                    .fill(viewModel.allConfirmed ? Color.safeGreen : Color.alertRed)
                    .frame(width: 12, height: 12)
            }

            HStack(spacing: 16) {
                StatusCard(
                    title: "Confirmed",
                    count: viewModel.confirmedCount,
                    color: .safeGreen
                )

                StatusCard(
                    title: "Pending",
                    count: viewModel.pendingCount,
                    color: .infoBlue
                )

                StatusCard(
                    title: "Missed",
                    count: viewModel.missedCount,
                    color: .alertRed
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)

            Text("No Family Members")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primaryText)

            Text("Add family members to start tracking their check-ins")
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    private var familyMembersList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.familyMembers, id: \.objectID) { member in
                FamilyMemberCard(
                    member: member,
                    status: viewModel.getStatus(for: member),
                    lastCheckIn: viewModel.getLastCheckIn(for: member),
                    onCall: { viewModel.callMember(member) },
                    onMessage: { viewModel.messageMember(member) }
                )
            }
        }
    }
}

struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FamilyMemberCard: View {
    let member: Parent
    let status: CheckInStatus
    let lastCheckIn: Date?
    let onCall: () -> Void
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.infoBlue)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.name ?? "Unknown")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primaryText)

                    Image(systemName: status.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(statusColor)
                }

                if let lastCheckIn = lastCheckIn {
                    Text("Last check-in: \(lastCheckIn.relativeString)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                } else {
                    Text("No check-ins yet")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onCall) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.safeGreen)
                        .frame(width: 40, height: 40)
                        .background(Color.safeGreen.opacity(0.15))
                        .cornerRadius(20)
                }

                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.infoBlue)
                        .frame(width: 40, height: 40)
                        .background(Color.infoBlue.opacity(0.15))
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .secondaryText
        case .confirmed: return .safeGreen
        case .missed: return .alertRed
        case .custom: return .infoBlue
        }
    }
}

@MainActor
class ChildDashboardViewModel: ObservableObject {
    @Published var familyMembers: [Parent] = []
    @Published var allConfirmed: Bool = false
    @Published var confirmedCount: Int = 0
    @Published var pendingCount: Int = 0
    @Published var missedCount: Int = 0

    private let parent: Parent
    private let checkInService = CheckInService.shared
    private let familyService = FamilyService.shared

    init(parent: Parent) {
        self.parent = parent
        refresh()
    }

    func refresh() {
        if let family = parent.familyCircle {
            familyMembers = familyService.fetchAllMembers(in: family)
                .filter { $0.role == UserRole.parent.rawValue }
        } else {
            familyMembers = []
        }

        updateCounts()
    }

    func getStatus(for member: Parent) -> CheckInStatus {
        return checkInService.getCheckInStatus(for: member)
    }

    func getLastCheckIn(for member: Parent) -> Date? {
        return checkInService.fetchLatestCheckIn(for: member)?.timestamp
    }

    func callMember(_ member: Parent) {
        if let phoneNumber = member.phoneNumber,
           let url = URL(string: "tel://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    func messageMember(_ member: Parent) {
        if let phoneNumber = member.phoneNumber,
           let url = URL(string: "sms://\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }

    private func updateCounts() {
        var confirmed = 0
        var pending = 0
        var missed = 0

        for member in familyMembers {
            let status = getStatus(for: member)
            switch status {
            case .confirmed:
                confirmed += 1
            case .pending:
                pending += 1
            case .missed:
                missed += 1
            case .custom:
                pending += 1
            }
        }

        confirmedCount = confirmed
        pendingCount = pending
        missedCount = missed
        allConfirmed = pending == 0 && missed == 0 && confirmed > 0
    }
}

#Preview {
    NavigationStack {
        ChildDashboardView(currentParent: Parent())
    }
}
