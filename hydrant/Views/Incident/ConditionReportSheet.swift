//
//  ConditionReportSheet.swift
//  hydrant
//
//  The "Laporkan Kondisi" form. One tap for a temporary report, a lasting warning
//  for a permanent one. Deliberately low-friction: pick a condition, optionally add
//  a note, submit. Attribution and time come from the device, not the officer.
//

import SwiftUI

struct ConditionReportSheet: View {
    let hydrant: Hydrant
    let incidentID: UUID?
    var onSubmit: (ConditionLevel, HydrantCondition, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var level: ConditionLevel = .sesaat
    @State private var condition: HydrantCondition = .aksesTerhalang
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(hydrant.title)
                        .font(.headline)
                    Text(hydrant.alamat.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Tingkat") {
                    Picker("Tingkat", selection: $level) {
                        ForEach(ConditionLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(level.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Kondisi") {
                    ForEach(HydrantCondition.allCases) { option in
                        Button {
                            condition = option
                        } label: {
                            HStack {
                                Label(option.title, systemImage: option.systemImage)
                                    .foregroundStyle(option.isProblem ? .primary : Color.green)
                                Spacer()
                                if condition == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Catatan (opsional)") {
                    TextField("mis. lapak menutup akses", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Laporkan Kondisi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kirim") {
                        onSubmit(level, condition, note)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
