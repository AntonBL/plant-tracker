import SwiftUI
import PhotosUI
import SwiftData

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultReminderTime") private var defaultReminderTimeInterval: Double = 32400 // 9:00 AM
    let plant: Plant

    @State private var viewModel: PlantDetailViewModel?
    @State private var showPhotosPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCadenceEditor = false
    @State private var newCadenceDays = 3
    @State private var newReminderTime = Date()
    @State private var showChat = false
    @State private var isAnalyzing = false
    @State private var showCamera = false
    @State private var showReanalysisSheet = false
    @State private var customPromptForReanalysis = ""
    @State private var reanalysisImage: UIImage?
    @State private var reanalysisPhoto: PhotosPickerItem?
    @State private var showReanalysisCamera = false
    @State private var showDeleteConfirmation = false

    private var defaultReminderTime: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = Int(defaultReminderTimeInterval) / 3600
        components.minute = (Int(defaultReminderTimeInterval) % 3600) / 60
        return calendar.date(from: components) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Plant image
                if let imagePath = plant.imagePath,
                   let image = ImageService.loadImage(from: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.green)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Plant info
                VStack(alignment: .leading, spacing: 8) {
                    Text(plant.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if let species = plant.species {
                        Text(species)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Latest assessment
                if let assessment = plant.latestAssessment {
                    assessmentCard(assessment)
                }

                // Watering info
                wateringCard

                // Actions
                VStack(spacing: 12) {
                    // Water now button
                    Button {
                        Task {
                            await viewModel?.recordWatering()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "drop.fill")
                            Text(viewModel?.isWatering == true ? "Recording..." : "Water Now")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel?.isWatering == true)

                    // Re-analyze button
                    Button {
                        showReanalysisSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(isAnalyzing ? "Analyzing..." : "Re-analyze Plant")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(isAnalyzing)

                    // Chat button
                    NavigationLink(destination: ChatView(plant: plant)) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right")
                            Text("Chat with AI")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Plant Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete Plant", isPresented: $showDeleteConfirmation) {
            Button("Delete Plant", role: .destructive) {
                deletePlant()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(plant.name)? This action cannot be undone.")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PlantDetailViewModel(plant: plant, modelContext: modelContext)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel?.showError ?? false },
            set: { if !$0 { viewModel?.showError = false } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel?.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showCadenceEditor) {
            cadenceEditorSheet
        }
        .sheet(isPresented: $showReanalysisSheet) {
            reanalysisSheet
        }
    }

    @ViewBuilder
    private func assessmentCard(_ assessment: Assessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest Assessment")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(for: assessment.status))
                        .frame(width: 8, height: 8)
                    Text(assessment.statusDisplayText)
                        .font(.subheadline)
                }
            }

            if !assessment.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ForEach(assessment.issues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                            Text(issue)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            if !assessment.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    ForEach(assessment.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                            Text(recommendation)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Text("Analyzed \(assessment.createdAt, style: .relative) ago")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var wateringCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watering Schedule")
                .font(.headline)

            if let cadence = plant.wateringCadenceDays {
                HStack {
                    VStack(alignment: .leading) {
                        // Display cadence with time
                        if cadence == 0 {
                            if let reminderTime = plant.reminderTime {
                                Text("Daily at \(reminderTime, style: .time)")
                                    .font(.subheadline)
                            } else {
                                Text("Daily")
                                    .font(.subheadline)
                            }
                        } else {
                            if let reminderTime = plant.reminderTime {
                                Text("Every \(cadence) days at \(reminderTime, style: .time)")
                                    .font(.subheadline)
                            } else {
                                Text("Every \(cadence) days")
                                    .font(.subheadline)
                            }
                        }

                        if let lastWatered = plant.lastWatered {
                            Text("Last watered \(lastWatered, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let nextWatering = plant.nextWateringDate {
                            Text("Next: \(nextWatering, style: .date)")
                                .font(.caption)
                                .foregroundStyle(plant.needsWatering ? .orange : .secondary)
                        }
                    }

                    Spacer()

                    Button {
                        newCadenceDays = cadence
                        newReminderTime = plant.reminderTime ?? defaultReminderTime
                        showCadenceEditor = true
                    } label: {
                        Text("Edit")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                Button {
                    newCadenceDays = Constants.defaultWateringCadenceDays
                    newReminderTime = defaultReminderTime
                    showCadenceEditor = true
                } label: {
                    Text("Set Watering Cadence")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private var cadenceEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Frequency") {
                    Picker("Water every", selection: $newCadenceDays) {
                        ForEach(0...365, id: \.self) { days in
                            if days == 0 {
                                Text("Daily").tag(days)
                            } else {
                                Text("\(days) days").tag(days)
                            }
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("Reminder Time") {
                    DatePicker("Time", selection: $newReminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }
            }
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCadenceEditor = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel?.updateCadence(newCadenceDays, reminderTime: newReminderTime)
                        showCadenceEditor = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var reanalysisSheet: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let image = reanalysisImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Menu {
                        PhotosPicker(selection: $reanalysisPhoto, matching: .images) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }

                        Button {
                            showReanalysisCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                    } label: {
                        Label(
                            reanalysisImage == nil ? "Add Photo" : "Change Photo",
                            systemImage: reanalysisImage == nil ? "photo.badge.plus" : "photo"
                        )
                    }
                }
                .onChange(of: reanalysisPhoto) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            reanalysisImage = image
                        }
                    }
                }
                .sheet(isPresented: $showReanalysisCamera) {
                    ImagePicker(image: $reanalysisImage, sourceType: .camera)
                }

                Section("Questions or Concerns (Optional)") {
                    TextField(
                        "e.g., Why are the leaves turning brown?",
                        text: $customPromptForReanalysis,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                }
            }
            .navigationTitle("Re-analyze Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showReanalysisSheet = false
                        reanalysisImage = nil
                        reanalysisPhoto = nil
                        customPromptForReanalysis = ""
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Analyze") {
                        Task {
                            if let image = reanalysisImage {
                                isAnalyzing = true
                                await viewModel?.analyze(
                                    image: image,
                                    customPrompt: customPromptForReanalysis.isEmpty
                                        ? nil
                                        : customPromptForReanalysis
                                )
                                isAnalyzing = false
                                showReanalysisSheet = false
                                reanalysisImage = nil
                                reanalysisPhoto = nil
                                customPromptForReanalysis = ""
                            }
                        }
                    }
                    .disabled(reanalysisImage == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "healthy":
            return .green
        case "needs_attention":
            return .orange
        case "critical":
            return .red
        default:
            return .gray
        }
    }

    private func deletePlant() {
        // Cancel any scheduled notifications
        NotificationService.shared.cancelReminder(for: plant.id)

        // Delete associated images
        if let imagePath = plant.imagePath {
            ImageService.deleteImage(at: imagePath)
        }

        // Delete all chat message images
        for message in plant.chatMessages {
            if let imageFilename = message.imageFilename {
                ImageService.deleteImage(at: imageFilename)
            }
        }

        // Delete the plant (cascade delete will handle assessments, watering events, and chat messages)
        modelContext.delete(plant)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete plant: \(error)")
        }
    }
}

#Preview {
    let plant = Plant(
        name: "Monstera",
        species: "Monstera deliciosa",
        wateringCadenceDays: 7,
        lastWatered: Date().addingTimeInterval(-3 * 24 * 60 * 60)
    )
    return NavigationStack {
        PlantDetailView(plant: plant)
            .modelContainer(for: [Plant.self, Assessment.self, WateringEvent.self, ChatMessage.self])
    }
}
