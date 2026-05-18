import SwiftUI

// A modal bottom sheet for the trip form.
// @Environment(\.dismiss) is the modern SwiftUI way to close a sheet —
// equivalent to calling a passed-in onClose() callback.
struct TripInputSheet: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    // Local state for the form. @State is local to this view — not shared.
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    @State private var airport = "SNA"
    @State private var skill = "intermediate"
    @State private var budget = "mid"

    var body: some View {
        NavigationStack {
            Form {
                // DatePicker is a built-in SwiftUI component.
                // .graphical shows a full calendar; .compact shows a tappable date label.
                Section("Trip Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("Origin Airport") {
                    // Picker with .menu style renders as a dropdown — clean for a short list.
                    Picker("Airport", selection: $airport) {
                        Text("SNA — Orange County").tag("SNA")
                        Text("LAX — Los Angeles").tag("LAX")
                        Text("SFO — San Francisco").tag("SFO")
                        Text("JFK — New York").tag("JFK")
                        Text("ORD — Chicago").tag("ORD")
                    }
                    .pickerStyle(.menu)
                }

                Section("Your Profile") {
                    Picker("Skill Level", selection: $skill) {
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                        Text("Expert").tag("expert")
                    }
                    .pickerStyle(.menu)

                    Picker("Budget", selection: $budget) {
                        Text("Budget").tag("budget")
                        Text("Mid-range").tag("mid")
                        Text("Premium").tag("premium")
                        Text("Luxury").tag("luxury")
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    // Duration calculated live from the two dates
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                    HStack {
                        Text("Trip length")
                        Spacer()
                        Text("\(days + 1) days")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Plan a Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        chatVM.trip = TripInput(
                            startDate: startDate,
                            endDate: endDate,
                            originAirport: airport,
                            skillLevel: skill,
                            budgetLevel: budget
                        )
                        dismiss()
                    }
                }
            }
        }
        // presentationDetents controls how tall the sheet snaps to.
        // .medium = half screen, .large = full screen.
        .presentationDetents([.medium, .large])
    }
}
