import SwiftUI

struct AnalysisResultView: View {
    let result: AnalyzeResponse
    let onSave: (Int) -> Void

    @State private var customCadence: String = ""
    @State private var useSuggestedCadence = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status header
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                Text(statusText)
                    .font(.headline)

                Spacer()

                Text("\(Int(result.confidence * 100))% confident")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Issues
            if !result.issues.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Issues")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(result.issues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text(issue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recommendations
            if !result.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(result.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(recommendation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Rationale
            if let rationale = result.rationale {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rationale")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(rationale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Watering cadence
            VStack(alignment: .leading, spacing: 12) {
                Text("Set Watering Cadence")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let suggestedInterval = result.suggestedIntervalDays {
                    Toggle(isOn: $useSuggestedCadence) {
                        Text("Use suggested: every \(suggestedInterval) days")
                            .font(.subheadline)
                    }
                }

                if !useSuggestedCadence || result.suggestedIntervalDays == nil {
                    HStack {
                        Text("Water every")
                            .font(.subheadline)

                        TextField("7", text: $customCadence)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)

                        Text("days")
                            .font(.subheadline)
                    }
                }

                Button {
                    let cadence: Int
                    if useSuggestedCadence, let suggested = result.suggestedIntervalDays {
                        cadence = suggested
                    } else {
                        cadence = Int(customCadence) ?? Constants.defaultWateringCadenceDays
                    }
                    onSave(cadence)
                } label: {
                    Text("Save Plant")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            if let suggested = result.suggestedIntervalDays {
                customCadence = String(suggested)
            } else {
                customCadence = String(Constants.defaultWateringCadenceDays)
            }
        }
    }

    private var statusColor: Color {
        switch result.status.lowercased() {
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

    private var statusText: String {
        switch result.status.lowercased() {
        case "healthy":
            return "Healthy"
        case "needs_attention":
            return "Needs Attention"
        case "critical":
            return "Critical"
        default:
            return "Unknown"
        }
    }
}

#Preview {
    AnalysisResultView(
        result: AnalyzeResponse(
            status: "needs_attention",
            confidence: 0.85,
            issues: ["Leaves showing yellowing", "Soil appears dry"],
            recommendations: ["Water thoroughly", "Increase humidity"],
            suggestedIntervalDays: 6,
            rationale: "Mild under-watering detected",
            suggestedName: nil
        ),
        onSave: { _ in }
    )
    .padding()
}
