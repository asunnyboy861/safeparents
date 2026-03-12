import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                List {
                    profileSection

                    notificationsSection

                    familyCircleSection

                    aboutSection
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadCurrentParent()
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.infoBlue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.parentName)
                        .font(.system(size: 17, weight: .medium))

                    Text(viewModel.parentRole)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }

                Spacer()
            }
            .padding(.vertical, 8)

            NavigationLink {
                EditProfileView(parent: viewModel.currentParent!)
            } label: {
                Label("Edit Profile", systemImage: "pencil")
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $viewModel.notificationsEnabled) {
                Label("Push Notifications", systemImage: "bell.fill")
            }
            .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                if newValue {
                    viewModel.requestNotificationPermission()
                }
            }

            NavigationLink {
                NotificationSettingsView()
            } label: {
                Label("Notification Settings", systemImage: "gearshape")
            }
        }
    }

    private var familyCircleSection: some View {
        Section("Family Circle") {
            if viewModel.familyName != nil {
                HStack {
                    Label("Family Name", systemImage: "person.3.fill")
                    Spacer()
                    Text(viewModel.familyName ?? "")
                        .foregroundColor(.secondaryText)
                }

                NavigationLink {
                    FamilyMembersView(family: viewModel.currentFamily!)
                } label: {
                    Label("Manage Members", systemImage: "person.2.fill")
                }

                Button(role: .destructive) {
                    viewModel.leaveFamilyCircle()
                } label: {
                    Label("Leave Family", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } else {
                Button {
                    viewModel.createFamilyCircle()
                } label: {
                    Label("Create Family Circle", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondaryText)
            }

            NavigationLink {
                FeedbackView()
            } label: {
                Label("Send Feedback", systemImage: "envelope.fill")
            }

            Link(destination: URL(string: "https://safeparents.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: "https://safeparents.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
        }
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var parentName: String = "User"
    @Published var parentRole: String = "Parent"
    @Published var notificationsEnabled: Bool = true
    @Published var familyName: String?
    @Published var currentParent: Parent?
    @Published var currentFamily: FamilyCircle?

    private let familyService = FamilyService.shared
    private let notificationService = NotificationService.shared

    func loadCurrentParent() {
        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<Parent> = Parent.fetchRequest()
        request.fetchLimit = 1

        do {
            if let parent = try context.fetch(request).first {
                currentParent = parent
                parentName = parent.name ?? "User"
                parentRole = parent.role?.capitalized ?? "Parent"
                currentFamily = parent.familyCircle
                familyName = parent.familyCircle?.name
            }
        } catch {
            print("Error loading parent: \(error)")
        }
    }

    func requestNotificationPermission() {
        Task {
            _ = try? await notificationService.requestAuthorization()
        }
    }

    func createFamilyCircle() {
        let family = familyService.createFamilyCircle(name: "\(parentName)'s Family")
        if let parent = currentParent {
            parent.familyCircle = family
            CoreDataStack.shared.save()
            currentFamily = family
            familyName = family.name
        }
    }

    func leaveFamilyCircle() {
        if let family = currentFamily {
            familyService.deleteFamilyCircle(family)
            currentFamily = nil
            familyName = nil
        }
    }
}

struct EditProfileView: View {
    let parent: Parent
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Phone Number (optional)", text: $phoneNumber)
                    .keyboardType(.phonePad)
            }

            Section {
                Button("Save Changes") {
                    saveChanges()
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = parent.name ?? ""
            phoneNumber = parent.phoneNumber ?? ""
        }
    }

    private func saveChanges() {
        parent.name = name
        parent.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        CoreDataStack.shared.save()
    }
}

import CoreData

struct NotificationSettingsView: View {
    @State private var soundEnabled: Bool = true
    @State private var vibrationEnabled: Bool = true

    var body: some View {
        Form {
            Section("Alert Settings") {
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Vibration", isOn: $vibrationEnabled)
            }

            Section("Quiet Hours") {
                DatePicker("Start Time", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: .constant(Date()), displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FamilyMembersView: View {
    let family: FamilyCircle
    @StateObject private var viewModel: FamilyMembersViewModel

    init(family: FamilyCircle) {
        self.family = family
        _viewModel = StateObject(wrappedValue: FamilyMembersViewModel(family: family))
    }

    var body: some View {
        List {
            ForEach(viewModel.members, id: \.objectID) { member in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.infoBlue)

                    VStack(alignment: .leading) {
                        Text(member.name ?? "Unknown")
                            .font(.system(size: 17, weight: .medium))

                        Text(member.role?.capitalized ?? "Parent")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .onDelete { indexSet in
                viewModel.deleteMembers(at: indexSet)
            }
        }
        .navigationTitle("Family Members")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showAddMember = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddMember) {
            AddMemberSheet(family: family, onAdd: { viewModel.refresh() })
        }
    }
}

@MainActor
class FamilyMembersViewModel: ObservableObject {
    @Published var members: [Parent] = []
    @Published var showAddMember: Bool = false

    private let familyService: FamilyService
    private let family: FamilyCircle

    init(family: FamilyCircle) {
        self.family = family
        self.familyService = FamilyService.shared
        refresh()
    }

    func refresh() {
        members = familyService.fetchAllMembers(in: family)
    }

    func deleteMembers(at offsets: IndexSet) {
        for index in offsets {
            let member = members[index]
            familyService.removeMember(member)
        }
        refresh()
    }
}

struct AddMemberSheet: View {
    let family: FamilyCircle
    let onAdd: () -> Void

    @State private var name: String = ""
    @State private var role: UserRole = .parent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Member Info") {
                    TextField("Name", text: $name)

                    Picker("Role", selection: $role) {
                        Text("Parent").tag(UserRole.parent)
                        Text("Child").tag(UserRole.child)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addMember() {
        let _ = FamilyService.shared.addMember(name: name, role: role, to: family)
        onAdd()
        dismiss()
    }
}
