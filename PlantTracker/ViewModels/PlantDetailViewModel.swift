import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class PlantDetailViewModel {
    private let modelContext: ModelContext
    private let proxyClient: GeminiProxyClient

    var plant: Plant
    var isAnalyzing = false
    var isWatering = false
    var errorMessage: String?
    var showError = false

    init(
        plant: Plant,
        modelContext: ModelContext,
        proxyClient: GeminiProxyClient = .shared
    ) {
        self.plant = plant
        self.modelContext = modelContext
        self.proxyClient = proxyClient
    }

    /// Analyze plant photo
    /// - Parameters:
    ///   - image: The plant photo to analyze
    ///   - customPrompt: Optional custom question or concern from user
    func analyze(image: UIImage, customPrompt: String? = nil) async {
        isAnalyzing = true
        errorMessage = nil
        showError = false

        do {
            // Compress image
            guard let imageData = ImageService.compressImage(image) else {
                throw AnalysisError.imageCompressionFailed
            }

            // Save image
            let filename = "\(plant.id)_\(Date().timeIntervalSince1970).jpg"
            if let imagePath = ImageService.saveImage(image, filename: filename) {
                plant.imagePath = imagePath
            }

            // Get season, format dates
            let season = getCurrentSeason()
            let lastWateredString = plant.lastWatered?.ISO8601Format()
            let currentDateString = Date().ISO8601Format()

            // Call proxy
            let response = try await proxyClient.analyze(
                imageData: imageData,
                plantName: plant.name,
                species: plant.species,
                season: season,
                lastWatered: lastWateredString,
                customPrompt: customPrompt,
                currentDate: currentDateString
            )

            // Create assessment from response
            let assessment = Assessment.from(response: response)
            assessment.plant = plant
            plant.assessments.append(assessment)

            // Save to SwiftData
            modelContext.insert(assessment)
            try modelContext.save()

            isAnalyzing = false

        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
            showError = true
            isAnalyzing = false
            print("Analysis error: \(error)")
        }
    }

    /// Record watering event
    func recordWatering() async {
        isWatering = true
        errorMessage = nil
        showError = false

        do {
            // Update last watered date
            plant.lastWatered = Date()

            // Create watering event
            let event = WateringEvent()
            event.plant = plant
            plant.wateringEvents.append(event)

            modelContext.insert(event)
            try modelContext.save()

            // Reschedule notification if cadence is set
            if plant.wateringCadenceDays != nil {
                NotificationService.shared.scheduleWateringReminder(for: plant)
            }

            isWatering = false

        } catch {
            errorMessage = "Failed to record watering: \(error.localizedDescription)"
            showError = true
            isWatering = false
            print("Watering error: \(error)")
        }
    }

    /// Update watering cadence and reminder time
    /// - Parameters:
    ///   - days: New cadence in days (0 for daily)
    ///   - reminderTime: Time of day for reminder
    func updateCadence(_ days: Int, reminderTime: Date) {
        plant.wateringCadenceDays = days
        plant.reminderTime = reminderTime

        do {
            try modelContext.save()

            // Reschedule notification with new cadence and time
            if plant.lastWatered != nil {
                NotificationService.shared.scheduleWateringReminder(for: plant)
            }
        } catch {
            errorMessage = "Failed to update cadence: \(error.localizedDescription)"
            showError = true
            print("Cadence update error: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        let isNorthernHemisphere = isSouthernHemisphere() == false

        if isNorthernHemisphere {
            switch month {
            case 3...5:
                return "spring"
            case 6...8:
                return "summer"
            case 9...11:
                return "fall"
            default:
                return "winter"
            }
        } else {
            // Southern hemisphere has opposite seasons
            switch month {
            case 3...5:
                return "fall"
            case 6...8:
                return "winter"
            case 9...11:
                return "spring"
            default:
                return "summer"
            }
        }
    }

    private func isSouthernHemisphere() -> Bool {
        // Use device locale's region to infer hemisphere
        // Southern hemisphere countries: Australia, New Zealand, South Africa,
        // Argentina, Chile, Brazil (partially), etc.
        guard let regionCode = Locale.current.region?.identifier else {
            return false // Default to Northern if unknown
        }

        let southernHemisphereCountries: Set<String> = [
            "AU", // Australia
            "NZ", // New Zealand
            "ZA", // South Africa
            "AR", // Argentina
            "CL", // Chile
            "UY", // Uruguay
            "PY", // Paraguay
            "BO", // Bolivia
            "PE", // Peru
            "EC", // Ecuador (on equator but included)
            "ID", // Indonesia (mostly southern)
            "MG", // Madagascar
            "MZ", // Mozambique
            "ZW", // Zimbabwe
            "BW", // Botswana
            "NA", // Namibia
            "AO", // Angola
            "ZM", // Zambia
            "MW", // Malawi
            "TZ", // Tanzania (partially)
            "PG", // Papua New Guinea
            "FJ", // Fiji
            "NC", // New Caledonia
        ]

        return southernHemisphereCountries.contains(regionCode)
    }
}

enum AnalysisError: LocalizedError {
    case imageCompressionFailed

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        }
    }
}
