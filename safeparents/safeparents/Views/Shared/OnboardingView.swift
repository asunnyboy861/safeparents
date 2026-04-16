import SwiftUI
import CoreData

struct OnboardingView: View {
    var onCompletion: () -> Void
    @State private var currentPage = 0
    @State private var navigateToProfileSetup = false
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    TabView(selection: $currentPage) {
                        welcomePage
                            .tag(0)

                        featurePage1
                            .tag(1)

                        featurePage2
                            .tag(2)

                        featurePage3
                            .tag(3)

                        createProfilePage
                            .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)

                    VStack(spacing: 16) {
                        if currentPage < 4 {
                            HStack(spacing: 8) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(index == currentPage ? Color.infoBlue : Color.secondaryText.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }

                            Button(action: {
                                withAnimation {
                                    currentPage += 1
                                }
                            }) {
                                Text(currentPage == 3 ? "Get Started" : "Continue")
                                    .font(.system(size: UIDevice.isIPad ? 20 : 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, UIDevice.isIPad ? 20 : 16)
                                    .background(Color.infoBlue)
                                    .cornerRadius(12)
                            }
                            .ipadAdaptiveButtonWidth()
                        }
                    }
                    .ipadAdaptivePadding()
                    .padding(.bottom, UIDevice.isIPad ? 50 : 32)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToProfileSetup) {
                ProfileSetupView(onCompletion: onCompletion)
                    .environment(\.managedObjectContext, viewContext)
                    .navigationBarHidden(true)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 120))
                .foregroundColor(.safeGreen)

            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.system(size: 20))
                    .foregroundColor(.secondaryText)

                Text("SafeParents")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primaryText)
            }

            Text("Peace of mind for the whole family")
                .font(.system(size: 17))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var featurePage1: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.safeGreen)

            VStack(spacing: 8) {
                Text("One-Tap Check-In")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
            }

            Text("Simply tap the button to confirm you're safe. It's that easy!")
                .font(.system(size: 17))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var featurePage2: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 100))
                .foregroundColor(.infoBlue)

            VStack(spacing: 8) {
                Text("Smart Reminders")
                    .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primaryText)
            }

            Text("Set up personalized check-in schedules and get gentle reminders")
                .font(.system(size: 17))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var featurePage3: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 100))
                .foregroundColor(.purple)

            VStack(spacing: 8) {
                Text("Family Circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)
            }

            Text("Keep your loved ones informed and stay connected as a family")
                .font(.system(size: 17))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var createProfilePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.infoBlue)

            Text("Create Your Profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primaryText)

            Text("Let's get you set up")
                .font(.system(size: 17))
                .foregroundColor(.secondaryText)

            Spacer()

            Button(action: {
                navigateToProfileSetup = true
            }) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.infoBlue)
                    .cornerRadius(12)
            }
            .ipadAdaptiveButtonWidth()
        }
        .padding()
    }
}

struct ProfileSetupView: View {
    var onCompletion: () -> Void
    @State private var name: String = ""
    @State private var role: UserRole = .parent
    @State private var isRequestingNotification = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Tell us about yourself")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)

                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("I am a")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)

                    Picker("Role", selection: $role) {
                        Text("Parent").tag(UserRole.parent)
                        Text("Child").tag(UserRole.child)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                if isRequestingNotification {
                    HStack {
                        ProgressView()
                        Text("Setting up notifications...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                    }
                } else {
                    Button(action: {
                        createProfile()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty ? Color.gray : Color.infoBlue)
                            .cornerRadius(12)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createProfile() {
        isRequestingNotification = true

        Task {
            await createProfileAsync()
        }
    }

    private func createProfileAsync() async {
        await MainActor.run {
            isRequestingNotification = true
        }

        do {
            try await saveProfileInBackground()

            try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    continuation.resume(throwing: CancellationError())
                }

                Task {
                    do {
                        _ = try await NotificationService.shared.requestAuthorization()
                        timeoutTask.cancel()
                        continuation.resume()
                    } catch {
                        timeoutTask.cancel()
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            print("Profile setup error (non-critical): \(error)")
        }

        await MainActor.run {
            isRequestingNotification = false
            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
            onCompletion()
        }
    }

    private func saveProfileInBackground() async throws {
        let coreDataStack = CoreDataStack.shared
        let backgroundContext = coreDataStack.newBackgroundContext()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            backgroundContext.perform {
                let parent = Parent(context: backgroundContext)
                parent.id = UUID()
                parent.name = self.name
                parent.role = self.role.rawValue
                parent.timeZone = TimeZone.current.identifier

                let schedule = CheckInSchedule(context: backgroundContext)
                schedule.id = UUID()
                schedule.timesArray = []
                schedule.daysArray = [1, 2, 3, 4, 5]
                schedule.reminderOffset = 60
                schedule.parent = parent
                parent.checkInSchedule = schedule

                coreDataStack.saveContext(backgroundContext)
                continuation.resume()
            }
        }
    }
}