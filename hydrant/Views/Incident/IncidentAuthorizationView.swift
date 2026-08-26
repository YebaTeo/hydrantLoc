//
//  IncidentAuthorizationView.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import SwiftUI

struct IncidentAuthorizationView: View {
    let title: String
    let message: String
    let onAuthorized: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var failedAttempts = 0
    @State private var cooldownRemaining = 0
    @FocusState private var isCodeFocused: Bool

    private let authorizationService = IncidentAuthorizationService()

    init(
        title: String = "Command Center Authorization",
        message: String = "Enter the 4-digit incident code",
        onAuthorized: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.onAuthorized = onAuthorized
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                codeInput

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    validateCode()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.count != 4 || cooldownRemaining > 0)

                Button("Cancel") {
                    resetSession()
                    dismiss()
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .navigationTitle("Authorization")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isCodeFocused = true
            }
            .onDisappear {
                resetSession()
            }
        }
    }

    private var codeInput: some View {
        ZStack {
            SecureField("Command Center authorization code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityLabel("Command Center authorization code")
                .onChange(of: code) { _, newValue in
                    let filteredCode = String(newValue.filter(\.isNumber).prefix(4))
                    if filteredCode != newValue {
                        code = filteredCode
                    }
                    if !filteredCode.isEmpty {
                        errorMessage = nil
                    }
                }

            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < code.count ? Color.primary : Color.secondary.opacity(0.25))
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .allowsHitTesting(false)
        }
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
                errorMessage = "Incorrect code. Try again."
            }
        }
    }

    private func startCooldown() {
        cooldownRemaining = 30
        errorMessage = "Too many incorrect attempts. Try again in 30 seconds."
        Task {
            while cooldownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                cooldownRemaining -= 1
                if cooldownRemaining > 0 {
                    errorMessage = "Too many incorrect attempts. Try again in \(cooldownRemaining) seconds."
                }
            }
            failedAttempts = 0
            errorMessage = nil
        }
    }

    private func resetInput() {
        code = ""
        errorMessage = nil
    }

    private func resetSession() {
        resetInput()
        failedAttempts = 0
        cooldownRemaining = 0
    }
}

#Preview {
    IncidentAuthorizationView(onAuthorized: {})
}
