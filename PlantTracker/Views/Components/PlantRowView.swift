import SwiftUI

struct PlantRowView: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: 12) {
            // Plant image or placeholder
            if let imagePath = plant.imagePath,
               let image = ImageService.loadImage(from: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .frame(width: 60, height: 60)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)

                if let species = plant.species {
                    Text(species)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Status and next watering
                HStack(spacing: 8) {
                    // Health status badge
                    if let assessment = plant.latestAssessment {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor(for: assessment.status))
                                .frame(width: 8, height: 8)
                            Text(assessment.statusDisplayText)
                                .font(.caption)
                        }
                    }

                    if let nextWatering = plant.nextWateringDate {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(plant.needsWatering ? "Needs water" : "Water \(nextWatering, style: .relative)")
                            .font(.caption)
                            .foregroundStyle(plant.needsWatering ? .orange : .secondary)
                    }
                }
            }

            Spacer()

            // Needs watering indicator
            if plant.needsWatering {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
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
}

#Preview {
    let plant = Plant(
        name: "Monstera",
        species: "Monstera deliciosa",
        wateringCadenceDays: 7,
        lastWatered: Date().addingTimeInterval(-8 * 24 * 60 * 60)
    )
    return PlantRowView(plant: plant)
        .padding()
}
