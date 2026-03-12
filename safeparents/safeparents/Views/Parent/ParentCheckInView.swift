import SwiftUI
import CoreData

struct ParentCheckInView: View {
    @StateObject private var viewModel = CheckInViewModel()
    @State private var isPressed = false
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentParent: Parent?

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: AppConstants.UI.largePadding) {
                Spacer()

                greetingSection

                Spacer()

                checkInButton

                Spacer()

                statusSection

                Spacer()
            }
            .padding(.horizontal, AppConstants.UI.standardPadding)
        }
        .navigationBarHidden(true)
        .onAppear {
            loadCurrentParent()
        }
    }

    private func loadCurrentParent() {
        let request: NSFetchRequest<Parent> = Parent.fetchRequest()
        request.fetchLimit = 1

        do {
            if let parent = try viewContext.fetch(request).first {
                currentParent = parent
                viewModel.loadParent(parent)
            }
        } catch {
            print("Error loading parent: \(error)")
        }
    }

    private var greetingSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.greeting)
                .font(.system(size: AppConstants.UI.headlineFontSize, weight: .medium))
                .foregroundColor(.primaryText)

            Text(viewModel.parentName)
                .font(.system(size: AppConstants.UI.bodyFontSize + 4, weight: .regular))
                .foregroundColor(.secondaryText)
        }
    }

    private var checkInButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            viewModel.confirmSafety()
            withAnimation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        viewModel.showSuccessAnimation
                            ? Color.safeGreen
                            : (isPressed ? Color.safeGreen.opacity(0.8) : Color.safeGreen)
                    )
                    .shadow(color: Color.safeGreen.opacity(0.3), radius: 20, x: 0, y: 10)

                if viewModel.showSuccessAnimation {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: AppConstants.UI.checkInIconSize))
                            .foregroundColor(.white)
                        Text("I'm OK")
                            .font(.system(size: AppConstants.UI.checkInFontSize, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: AppConstants.UI.checkInIconSize))
                            .foregroundColor(.white)
                        Text("I'm OK")
                            .font(.system(size: AppConstants.UI.checkInFontSize, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: AppConstants.UI.checkInButtonSize, height: AppConstants.UI.checkInButtonSize)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.statusText)
                .font(.system(size: AppConstants.UI.bodyFontSize, weight: .medium))
                .foregroundColor(viewModel.statusColor)

            Text(viewModel.lastCheckInText)
                .font(.system(size: AppConstants.UI.captionFontSize))
                .foregroundColor(.secondaryText)
        }
    }
}

#Preview {
    ParentCheckInView()
}
