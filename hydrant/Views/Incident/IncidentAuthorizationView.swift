//
//  IncidentAuthorizationView.swift
//  hydrant
//

import SwiftUI

// Command-center passcode gate with a self-contained on-screen keypad, so it never
// depends on the system keyboard or focus (which is unreliable inside the always-
// presented controller sheet).
struct IncidentAuthorizationView: View {
    let title: String
    let message: String
    let onAuthorized: () -> Void
    let onCancel: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var failedAttempts = 0
    @State private var cooldownRemaining = 0

    private let authorizationService = IncidentAuthorizationService()
    private let codeLength = 4

    private let keypad: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "⌫"]
    ]

    init(
        title: String = "Command Center Authorization",
        message: String = "Enter the 4-digit incident code",
        onAuthorized: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onAuthorized = onAuthorized
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            dots

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            keypadGrid

            Button("Batal") {
                resetSession()
                if let onCancel {
                    onCancel()
                } else {
                    dismiss()
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .onDisappear { resetSession() }
    }

    private var dots: some View {
        HStack(spacing: 16) {
            ForEach(0..<codeLength, id: \.self) { index in
                Circle()
                    .fill(index < code.count ? Color.primary : Color.secondary.opacity(0.25))
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityLabel("\(code.count) dari \(codeLength) digit dimasukkan")
    }

    private var keypadGrid: some View {
        VStack(spacing: 12) {
            ForEach(keypad, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key)
                    }
                }
            }
        }
        .disabled(cooldownRemaining > 0)
    }

    @ViewBuilder
    private func keypadButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 72, height: 72)
        } else if key == "⌫" {
            Button {
                deleteDigit()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.plain)
            .disabled(code.isEmpty)
            .accessibilityLabel("Hapus")
        } else {
            Button {
                appendDigit(key)
            } label: {
                Text(key)
                    .font(.title.weight(.medium))
                    .frame(width: 72, height: 72)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(key)
        }
    }

    private func appendDigit(_ digit: String) {
        guard cooldownRemaining == 0, code.count < codeLength else { return }
        code += digit
        errorMessage = nil
        if code.count == codeLength {
            validateCode()
        }
    }

    private func deleteDigit() {
        guard !code.isEmpty else { return }
        code.removeLast()
    }

    private func validateCode() {
        guard cooldownRemaining == 0 else { return }

        if authorizationService.validate(code: code) {
            resetSession()
            onAuthorized()
        } else {
            failedAttempts += 1
            code = ""
            if failedAttempts >= 3 {
                startCooldown()
            } else {
                errorMessage = "Kode salah. Coba lagi."
            }
        }
    }

    private func startCooldown() {
        cooldownRemaining = 30
        errorMessage = "Terlalu banyak percobaan. Coba lagi dalam 30 detik."
        Task {
            while cooldownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                cooldownRemaining -= 1
                if cooldownRemaining > 0 {
                    errorMessage = "Terlalu banyak percobaan. Coba lagi dalam \(cooldownRemaining) detik."
                }
            }
            failedAttempts = 0
            errorMessage = nil
        }
    }

    private func resetSession() {
        code = ""
        errorMessage = nil
        failedAttempts = 0
        cooldownRemaining = 0
    }
}

#Preview {
    IncidentAuthorizationView(onAuthorized: {})
}
