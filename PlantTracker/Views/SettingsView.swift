import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultReminderTime") private var defaultReminderTimeInterval: Double = 32400 // 9:00 AM in seconds

    private var defaultReminderTime: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: defaultReminderTimeInterval))
                return calendar.date(from: components) ?? Date()
            },
            set: { newValue in
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: newValue)
                let seconds = (components.hour ?? 9) * 3600 + (components.minute ?? 0) * 60
                defaultReminderTimeInterval = Double(seconds)
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Default Reminder Time",
                        selection: defaultReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("This time will be used as the default for new watering reminders. You can customize it for each plant individually.")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
