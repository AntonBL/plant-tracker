import SwiftUI
import SwiftData
import PhotosUI

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    let plant: Plant

    @State private var viewModel: ChatViewModel?
    @State private var messageText = ""
    @State private var showClearConfirmation = false
    @State private var selectedImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showImageOptions = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        if viewModel.messages.isEmpty {
                            emptyState
                        } else {
                            messagesView(viewModel: viewModel)
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Scroll to bottom when new message arrives
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                inputArea(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Chat with AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let viewModel = viewModel, !viewModel.messages.isEmpty {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChatViewModel(plant: plant, modelContext: modelContext)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel?.showError ?? false },
            set: { if !$0 { viewModel?.showError = false } }
        )) {
            Button("OK", role: .cancel) {}
            Button("Retry") {
                // Retry last message
                Task {
                    await viewModel?.sendMessage(messageText)
                }
            }
        } message: {
            if let error = viewModel?.errorMessage {
                Text(error)
            }
        }
        .confirmationDialog(
            "Clear Chat History",
            isPresented: $showClearConfirmation
        ) {
            Button("Clear All Messages", role: .destructive) {
                viewModel?.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all chat messages for \(plant.name).")
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Ask me anything about \(plant.name)!")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("I can help with watering schedules, pest problems, and general plant care.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private func messagesView(viewModel: ChatViewModel) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.messages) { message in
                MessageBubble(message: message)
                    .id(message.id)
            }

            if viewModel.isSending {
                HStack {
                    ProgressView()
                        .padding(.horizontal, 8)
                    Text("Thinking...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func inputArea(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            Divider()

            // Image preview if selected
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Button {
                        selectedImage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            HStack(spacing: 12) {
                // Image attachment button
                Button {
                    showImageOptions = true
                } label: {
                    Image(systemName: selectedImage != nil ? "photo.fill" : "photo")
                        .font(.title2)
                        .foregroundStyle(selectedImage != nil ? .blue : .gray)
                }
                .disabled(viewModel.isSending)
                .confirmationDialog("Add Image", isPresented: $showImageOptions) {
                    Button("Take Photo") {
                        showCamera = true
                    }
                    Button("Choose from Library") {
                        showPhotoPicker = true
                    }
                    if selectedImage != nil {
                        Button("Remove Image", role: .destructive) {
                            selectedImage = nil
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                TextField("Ask about your plant...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .disabled(viewModel.isSending)

                Button {
                    Task {
                        let message = messageText
                        let image = selectedImage
                        messageText = ""
                        selectedImage = nil
                        await viewModel.sendMessage(message, image: image)
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty || viewModel.isSending ? .gray : .blue)
                }
                .disabled(messageText.isEmpty || viewModel.isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Show image if present
                if let path = message.imageFilename,
                   let uiImage = ImageService.loadImage(from: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Action suggestions (assistant only)
                if message.isAssistant, let suggestions = message.actionSuggestions, !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested Actions:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(suggestions, id: \.self) { suggestion in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                Text(suggestion)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Safety note (assistant only)
                if message.isAssistant, let safetyNote = message.safetyNote {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                        Text(safetyNote)
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.isAssistant {
                Spacer()
            }
        }
    }
}

#Preview {
    let plant = Plant(
        name: "Monstera",
        species: "Monstera deliciosa"
    )
    return NavigationStack {
        ChatView(plant: plant)
            .modelContainer(for: [Plant.self, ChatMessage.self])
    }
}
