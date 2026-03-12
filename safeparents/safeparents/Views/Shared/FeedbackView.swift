import SwiftUI

struct FeedbackView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        formSection

                        submitButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Thank You!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your feedback has been submitted successfully. We appreciate your input!")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 50))
                .foregroundColor(.infoBlue)

            Text("We'd Love to Hear From You")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)

            Text("Help us improve SafeParents by sharing your feedback, suggestions, or reporting issues.")
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)

                TextField("Enter your name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Email (Optional)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)

                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Subject")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)

                TextField("What's this about?", text: $subject)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)

                TextEditor(text: $message)
                    .frame(minHeight: 150)
                    .padding(4)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor.separator), lineWidth: 0.5)
                    )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(AppConstants.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var submitButton: some View {
        Button(action: {
            submitFeedback()
        }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                }

                Text(isSubmitting ? "Submitting..." : "Submit Feedback")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.infoBlue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSubmitting)
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submitFeedback() {
        guard isFormValid else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let response = try await FeedbackService.shared.submitFeedback(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    subject: subject.trimmingCharacters(in: .whitespaces),
                    message: message.trimmingCharacters(in: .whitespaces)
                )

                await MainActor.run {
                    isSubmitting = false

                    if response.success {
                        showSuccess = true
                    } else {
                        errorMessage = response.error ?? "Failed to submit feedback"
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    FeedbackView()
}
