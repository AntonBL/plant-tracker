import SwiftUI
import PhotosUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    let onDismiss: () -> Void

    // Navigation state
    @State private var currentStep: AddPlantStep = .photoCapture

    // Photo state
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    // Plant data
    @State private var name = ""
    @State private var species = ""
    @State private var customPrompt = ""

    // Analysis state
    @State private var isAnalyzing = false
    @State private var analysisResult: AnalyzeResponse?
    @State private var errorMessage: String?
    @State private var showError = false

    private let proxyClient = GeminiProxyClient.shared

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .photoCapture:
                    photoCaptureView
                case .analyzing:
                    analyzingView
                case .editDetails:
                    editDetailsView
                case .manualEntry:
                    manualEntryView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .alert("Analysis Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    currentStep = .editDetails
                }
                Button("Retry") {
                    Task {
                        await analyzePhoto()
                    }
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        // Auto-trigger analysis after photo selection
                        await analyzePhoto()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedImage) { oldValue, newValue in
                // If image was set via camera (not PhotosPicker), trigger analysis
                if oldValue == nil && newValue != nil && selectedPhoto == nil {
                    Task {
                        await analyzePhoto()
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Photo Capture

    @ViewBuilder
    private var photoCaptureView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Instructions
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("Add a Photo of Your Plant")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Get AI-powered health analysis and care recommendations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Photo buttons
            VStack(spacing: 16) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)

            // Skip button
            Button {
                currentStep = .manualEntry
            } label: {
                Text("Skip")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 2: Analyzing

    @ViewBuilder
    private var analyzingView: some View {
        VStack(spacing: 24) {
            Spacer()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Analyzing Your Plant...")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("This may take a few seconds")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Step 3: Edit Details (After Analysis)

    @ViewBuilder
    private var editDetailsView: some View {
        Form {
            // Photo preview
            if let image = selectedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Plant details
            Section("Plant Information") {
                // Show AI-suggested name if available and name is empty
                if name.isEmpty, let suggestedName = analysisResult?.suggestedName {
                    aiNameSuggestionView(suggestedName)
                }

                TextField("Name", text: $name)
                TextField("Species (optional)", text: $species)
            }

            // Questions or Concerns section
            Section("Questions or Concerns (Optional)") {
                TextField(
                    "e.g., Why are the leaves turning brown?",
                    text: $customPrompt,
                    axis: .vertical
                )
                .lineLimit(2...5)
            }

            // Analysis results
            if let result = analysisResult {
                Section {
                    AnalysisResultView(
                        result: result,
                        onSave: { cadence in
                            savePlant(cadence: cadence)
                        }
                    )
                }
            }

            // Save button if no analysis or analysis didn't provide save option
            if analysisResult == nil {
                Section {
                    Button {
                        savePlant(cadence: nil)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Plant")
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 4: Manual Entry (Skip Path)

    @ViewBuilder
    private var manualEntryView: some View {
        Form {
            Section("Plant Information") {
                TextField("Name", text: $name)
                TextField("Species (optional)", text: $species)
            }

            Section {
                Button {
                    savePlant(cadence: nil)
                } label: {
                    HStack {
                        Spacer()
                        Text("Save Plant")
                        Spacer()
                    }
                }
                .disabled(name.isEmpty)
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func aiNameSuggestionView(_ suggestedName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Suggestion")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text(suggestedName)
                    .font(.headline)
                Spacer()
                Button("Use This Name") {
                    name = suggestedName
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        switch currentStep {
        case .photoCapture:
            return "Add Plant"
        case .analyzing:
            return "Analyzing"
        case .editDetails:
            return "Plant Details"
        case .manualEntry:
            return "Add Plant"
        }
    }

    private func analyzePhoto() async {
        guard let image = selectedImage else { return }

        currentStep = .analyzing
        isAnalyzing = true
        errorMessage = nil
        showError = false

        do {
            // Compress image
            guard let imageData = ImageService.compressImage(image) else {
                throw AnalysisError.imageCompressionFailed
            }

            // Get season and current date
            let season = getCurrentSeason()
            let currentDateString = Date().ISO8601Format()

            // Call proxy (pass nil if name is empty so AI can suggest a name)
            let response = try await proxyClient.analyze(
                imageData: imageData,
                plantName: name.isEmpty ? nil : name,
                species: species.isEmpty ? nil : species,
                season: season,
                lastWatered: nil,
                customPrompt: customPrompt.isEmpty ? nil : customPrompt,
                currentDate: currentDateString
            )

            analysisResult = response
            isAnalyzing = false
            currentStep = .editDetails

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isAnalyzing = false
            // Stay on analyzing view, alert will offer retry or OK (which goes to editDetails)
        }
    }

    private func savePlant(cadence: Int?) {
        // Use "Unnamed Plant" if name is still empty
        let finalName = name.isEmpty ? "Unnamed Plant" : name

        // Create plant
        let plant = Plant(
            name: finalName,
            species: species.isEmpty ? nil : species,
            wateringCadenceDays: cadence,
            lastWatered: cadence != nil ? Date() : nil
        )

        // Save image if present
        if let image = selectedImage {
            let filename = "\(plant.id)_\(Date().timeIntervalSince1970).jpg"
            if let imagePath = ImageService.saveImage(image, filename: filename) {
                plant.imagePath = imagePath
            }
        }

        // Save plant to SwiftData
        modelContext.insert(plant)

        // Save assessment if we have one
        if let result = analysisResult {
            let assessment = Assessment.from(response: result)
            assessment.plant = plant
            plant.assessments.append(assessment)
            modelContext.insert(assessment)
        }

        do {
            try modelContext.save()

            // Schedule notification if cadence is set
            if cadence != nil {
                NotificationService.shared.scheduleWateringReminder(for: plant)
            }

            dismiss()
            onDismiss()
        } catch {
            errorMessage = "Failed to save plant: \(error.localizedDescription)"
            showError = true
        }
    }

    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "fall"
        default: return "winter"
        }
    }
}

// MARK: - Step Enum

enum AddPlantStep {
    case photoCapture
    case analyzing
    case editDetails
    case manualEntry
}

#Preview {
    AddPlantView(
        modelContext: ModelContext(
            try! ModelContainer(for: Plant.self, Assessment.self)
        ),
        onDismiss: {}
    )
}
