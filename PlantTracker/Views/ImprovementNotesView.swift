import SwiftUI
import SwiftData

struct ImprovementNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImprovementNote.createdAt, order: .reverse) private var notes: [ImprovementNote]

    @State private var showAddNote = false
    @State private var newNoteContent = ""

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Improvement Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddNote) {
                addNoteSheet
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("No Improvement Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the + button to add ideas for app improvements")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddNote = true
            } label: {
                Label("Add Note", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
    }

    @ViewBuilder
    private var notesList: some View {
        List {
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 8) {
                    Text(note.content)
                        .font(.body)

                    Text(note.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteNotes)
        }
    }

    @ViewBuilder
    private var addNoteSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Enter your improvement idea...",
                        text: $newNoteContent,
                        axis: .vertical
                    )
                    .lineLimit(5...10)
                } header: {
                    Text("Improvement Idea")
                } footer: {
                    Text("Describe a feature or improvement you'd like to see in the app")
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newNoteContent = ""
                        showAddNote = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(newNoteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveNote() {
        let trimmedContent = newNoteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        let note = ImprovementNote(content: trimmedContent)
        modelContext.insert(note)

        do {
            try modelContext.save()
            newNoteContent = ""
            showAddNote = false
        } catch {
            print("Failed to save note: \(error)")
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = notes[index]
            modelContext.delete(note)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
}

#Preview {
    ImprovementNotesView()
        .modelContainer(for: [ImprovementNote.self])
}
