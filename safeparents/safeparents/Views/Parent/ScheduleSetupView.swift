import SwiftUI
import CoreData

struct ScheduleSetupView: View {
    @StateObject private var viewModel = ScheduleSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    let parent: Parent

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        timePickerSection

                        selectedTimesSection

                        daysOfWeekSection

                        reminderSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveAndScheduleNotifications()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            viewModel.loadSchedule(for: parent)
        }
    }

    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Check-in Time")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primaryText)

            DatePicker(
                "Select Time",
                selection: $viewModel.selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 150)

            Button(action: {
                viewModel.addTime()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Time")
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.infoBlue)
                .cornerRadius(AppConstants.UI.cornerRadius)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var selectedTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled Times")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primaryText)

                Spacer()

                if !viewModel.scheduledTimes.isEmpty {
                    Text("\(viewModel.scheduledTimes.count) time(s)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
            }

            if viewModel.scheduledTimes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondaryText)

                    Text("No times scheduled")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.scheduledTimes.enumerated()), id: \.offset) { index, time in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.infoBlue)

                            Text(time.timeString)
                                .font(.system(size: 17))
                                .foregroundColor(.primaryText)

                            Spacer()

                            Button(action: {
                                viewModel.removeTime(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.alertRed)
                            }
                        }
                        .padding()
                        .background(Color.background)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var daysOfWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days of Week")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primaryText)

            HStack(spacing: 8) {
                ForEach(0..<7) { index in
                    Button(action: {
                        viewModel.toggleDay(index)
                    }) {
                        Text(dayAbbreviation(index))
                            .font(.system(size: 14, weight: viewModel.selectedDays.contains(index) ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedDays.contains(index) ? .white : .primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.selectedDays.contains(index) ? Color.infoBlue : Color.background)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primaryText)

            Picker("Remind me before", selection: $viewModel.reminderOffset) {
                Text("30 minutes").tag(30)
                Text("1 hour").tag(60)
                Text("2 hours").tag(120)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func dayAbbreviation(_ day: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[day]
    }
}

@MainActor
class ScheduleSetupViewModel: ObservableObject {
    @Published var selectedTime = Date()
    @Published var scheduledTimes: [Date] = []
    @Published var selectedDays: [Int] = [1, 2, 3, 4, 5]
    @Published var reminderOffset: Int = 60

    private let scheduleService: ScheduleService
    private let notificationService: NotificationService
    private var currentSchedule: CheckInSchedule?
    private var currentParent: Parent?

    init(scheduleService: ScheduleService = .shared, notificationService: NotificationService = .shared) {
        self.scheduleService = scheduleService
        self.notificationService = notificationService
    }

    func loadSchedule(for parent: Parent) {
        currentParent = parent
        if let schedule = scheduleService.getSchedule(for: parent) {
            currentSchedule = schedule
            scheduledTimes = schedule.times ?? []
            selectedDays = (schedule.days as? [Int]) ?? [1, 2, 3, 4, 5]
            reminderOffset = Int(schedule.reminderOffset)
        }
    }

    func addTime() {
        guard scheduledTimes.count < AppConstants.CheckIn.maxScheduleTimes else { return }
        scheduledTimes.append(selectedTime)
        scheduledTimes.sort { $0.compare($1) == .orderedAscending }
        saveSchedule()
    }

    func removeTime(at index: Int) {
        guard index < scheduledTimes.count else { return }
        scheduledTimes.remove(at: index)
        saveSchedule()
    }

    func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
            selectedDays.sort()
        }
        saveSchedule()
    }

    private func saveSchedule() {
        guard let schedule = currentSchedule else { return }
        schedule.times = scheduledTimes
        schedule.days = selectedDays
        schedule.reminderOffset = Int32(reminderOffset)
        CoreDataStack.shared.save()
    }

    func saveAndScheduleNotifications() {
        saveSchedule()

        guard let parent = currentParent else { return }

        Task {
            do {
                try await notificationService.cancelNotifications(for: parent)

                for time in scheduledTimes {
                    try await notificationService.scheduleCheckInReminder(for: parent, at: time)
                }
            } catch {
                print("Error scheduling notifications: \(error)")
            }
        }
    }
}
