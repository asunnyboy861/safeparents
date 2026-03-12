import SwiftUI
import CoreData

struct FamilyManagementView: View {
    @StateObject private var viewModel = FamilyManagementViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddMember = false

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            if viewModel.family == nil {
                createFamilyView
            } else {
                familyListView
            }
        }
        .navigationTitle("Family")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.family != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMember = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddFamilyMemberSheet(family: viewModel.family!) {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadFamily()
        }
    }

    private var createFamilyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.infoBlue)

            VStack(spacing: 8) {
                Text("Create Your Family Circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primaryText)

                Text("Invite family members to stay connected")
                    .font(.system(size: 16))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.createFamily()
            } label: {
                Text("Create Family Circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.infoBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var familyListView: some View {
        List {
            Section("Family: \(viewModel.family?.name ?? "My Family")") {
                ForEach(viewModel.members, id: \.objectID) { member in
                    FamilyMemberRow(member: member) {
                        viewModel.removeMember(member)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeMember(viewModel.members[index])
                    }
                }
            }

            Section {
                Button {
                    showingAddMember = true
                } label: {
                    Label("Add Family Member", systemImage: "person.badge.plus")
                }
            }

            Section {
                Button(role: .destructive) {
                    viewModel.leaveFamily()
                } label: {
                    Label("Leave Family Circle", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct FamilyMemberRow: View {
    let member: Parent
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.infoBlue)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name ?? "Unknown")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primaryText)

                Text(member.role?.capitalized ?? "Member")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            if let phone = member.phoneNumber {
                Button {
                    if let url = URL(string: "tel://\(phone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.safeGreen)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFamilyMemberSheet: View {
    let family: FamilyCircle
    let onAdd: () -> Void

    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var role: UserRole = .parent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Member Information") {
                    TextField("Name", text: $name)

                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)

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
        let member = FamilyService.shared.addMember(name: name, role: role, to: family)
        member.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        CoreDataStack.shared.save()
        onAdd()
        dismiss()
    }
}

@MainActor
class FamilyManagementViewModel: ObservableObject {
    @Published var family: FamilyCircle?
    @Published var members: [Parent] = []

    private let familyService = FamilyService.shared
    private let coreDataStack = CoreDataStack.shared

    func loadFamily() {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<FamilyCircle> = FamilyCircle.fetchRequest()
        request.fetchLimit = 1

        do {
            family = try context.fetch(request).first
            refresh()
        } catch {
            print("Error loading family: \(error)")
        }
    }

    func createFamily() {
        let context = coreDataStack.viewContext

        let parentRequest: NSFetchRequest<Parent> = Parent.fetchRequest()
        parentRequest.fetchLimit = 1

        var familyName = "My Family"
        if let currentParent = try? context.fetch(parentRequest).first {
            familyName = "\(currentParent.name ?? "My")'s Family"
        }

        family = familyService.createFamilyCircle(name: familyName)
        refresh()
    }

    func refresh() {
        guard let family = family else {
            members = []
            return
        }
        members = familyService.fetchAllMembers(in: family)
    }

    func removeMember(_ member: Parent) {
        familyService.removeMember(member)
        refresh()
    }

    func leaveFamily() {
        if let family = family {
            familyService.deleteFamilyCircle(family)
            self.family = nil
            members = []
        }
    }
}

#Preview {
    NavigationStack {
        FamilyManagementView()
    }
}
