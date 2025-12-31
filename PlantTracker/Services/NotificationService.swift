import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    /// Request notification permission from user
    /// - Returns: True if authorized, false otherwise
    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Check current authorization status
    /// - Returns: Current notification authorization status
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }

    /// Schedule watering reminder for a plant
    /// - Parameter plant: The plant to schedule notification for
    func scheduleWateringReminder(for plant: Plant) {
        guard let cadenceDays = plant.wateringCadenceDays,
              let lastWatered = plant.lastWatered else {
            print("Cannot schedule reminder: missing cadence or last watered date")
            return
        }

        // Cancel existing reminder for this plant
        cancelReminder(for: plant.id)

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Water \(plant.name)"
        content.body = "Your \(plant.species ?? "plant") needs watering!"
        content.sound = .default
        content.userInfo = ["plantId": plant.id]

        let trigger: UNNotificationTrigger

        // Use calendar trigger if reminder time is set
        if let reminderTime = plant.reminderTime {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: reminderTime)
            let minute = calendar.component(.minute, from: reminderTime)

            if cadenceDays == 0 {
                // Daily reminders: repeat every day at specified time
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute

                trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )

                print("Scheduled daily watering reminder for \(plant.name) at \(hour):\(String(format: "%02d", minute))")

            } else {
                // N-day cadence: schedule at next occurrence
                let nextWateringDate = calendar.date(
                    byAdding: .day,
                    value: cadenceDays,
                    to: lastWatered
                ) ?? lastWatered

                // Set time to specified hour and minute
                var dateComponents = calendar.dateComponents(
                    [.year, .month, .day],
                    from: nextWateringDate
                )
                dateComponents.hour = hour
                dateComponents.minute = minute

                trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: false
                )

                if let targetDate = calendar.date(from: dateComponents) {
                    print("Scheduled watering reminder for \(plant.name) at \(targetDate)")
                }
            }

        } else {
            // Fallback to old behavior if no reminderTime is set
            guard let nextWateringDate = plant.nextWateringDate else {
                print("Cannot schedule reminder: no next watering date")
                return
            }

            let timeInterval = nextWateringDate.timeIntervalSinceNow

            guard timeInterval > 0 else {
                print("Cannot schedule reminder: date is in the past")
                return
            }

            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            )

            print("Scheduled watering reminder for \(plant.name) at \(nextWateringDate)")
        }

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: plant.id),
            content: content,
            trigger: trigger
        )

        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    /// Cancel watering reminder for a plant
    /// - Parameter plantId: ID of the plant
    func cancelReminder(for plantId: String) {
        let identifier = notificationIdentifier(for: plantId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled reminder for plant: \(plantId)")
    }

    /// Reschedule all plant reminders
    /// - Parameter plants: All plants to reschedule
    func rescheduleAllReminders(for plants: [Plant]) {
        // Cancel all pending notifications
        notificationCenter.removeAllPendingNotificationRequests()

        // Schedule new notifications for each plant with a cadence
        for plant in plants where plant.wateringCadenceDays != nil {
            scheduleWateringReminder(for: plant)
        }
    }

    /// Get all pending notification requests (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func notificationIdentifier(for plantId: String) -> String {
        "watering-\(plantId)"
    }
}
