import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlantListViewModel?
    @State private var showAddPlant = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.plants.isEmpty {
                        // Empty state
                        ContentUnavailableView(
                            "No Plants Yet",
                            systemImage: "leaf",
                            description: Text("Add your first plant to get started!")
                        )
                    } else {
                        plantList(viewModel: viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My Plants")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPlant = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPlant) {
                if let viewModel = viewModel {
                    AddPlantView(
                        modelContext: modelContext,
                        onDismiss: {
                            viewModel.loadPlants()
                        }
                    )
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: .constant(viewModel?.errorMessage != nil)) {
                Button("OK") {
                    viewModel?.errorMessage = nil
                }
            } message: {
                if let error = viewModel?.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PlantListViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func plantList(viewModel: PlantListViewModel) -> some View {
        List {
            // Plants needing water section
            if !viewModel.plantsNeedingWater.isEmpty {
                Section("Needs Water") {
                    ForEach(viewModel.plantsNeedingWater) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            PlantRowView(plant: plant)
                        }
                    }
                }
            }

            // All plants section
            Section("All Plants") {
                ForEach(viewModel.plants) { plant in
                    NavigationLink(destination: PlantDetailView(plant: plant)) {
                        PlantRowView(plant: plant)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deletePlant(viewModel.plants[index])
                    }
                }
            }
        }
        .refreshable {
            viewModel.loadPlants()
        }
    }
}

#Preview {
    PlantListView()
        .modelContainer(for: [Plant.self, Assessment.self, WateringEvent.self, ChatMessage.self])
}
