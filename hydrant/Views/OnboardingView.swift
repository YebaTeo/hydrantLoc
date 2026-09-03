////
////  OnboardingView.swift
////  hydrant
////
////  Created by Daffa Burane Nugraha on 26/08/26.
////
//
//import SwiftUI
//
//struct OnboardingView: View {
//
//    @Binding var hasCompletedOnboarding: Bool
//    @StateObject private var viewModel = OnboardingViewModel()
//
//    var body: some View {
//        ZStack(alignment: .top) {
//
//            Color.onboardingBackground
//                .ignoresSafeArea()
//
//            VStack(alignment: .leading, spacing: 0) {
//
//                header
//                    .padding(.top, 24)
//
//                formContent
//                    .padding(.top, 28)
//
//                Spacer()
//            }
//            .padding(.horizontal, 24)
//        }
//    }
//}
//
//
//// MARK: - Header
//
//private extension OnboardingView {
//
//    var header: some View {
//        HStack(alignment: .center) {
//
//            Text("Siapa Anda")
//                .font(
//                    .system(
//                        size: 28,
//                        weight: .bold
//                    )
//                )
//                .foregroundStyle(Color.onboardingTitle)
//
//            Spacer()
//
//            Button {
//                handleNext()
//            } label: {
//
//                Text("Next")
//                    .font(
//                        .system(
//                            size: 13,
//                            weight: .semibold
//                        )
//                    )
//                    .foregroundStyle(.white)
//                    .padding(.horizontal, 14)
//                    .frame(height: 32)
//                    .background(
//                        viewModel.canContinue
//                        ? Color.onboardingButtonActive
//                        : Color.onboardingButtonInactive
//                    )
//                    .clipShape(Capsule())
//            }
//            .buttonStyle(.plain)
//            .disabled(!viewModel.canContinue)
//        }
//    }
//}
//
//
//// MARK: - Form
//
//private extension OnboardingView {
//
//    var formContent: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 20
//        ) {
//
//            roleSection
//
//            taskForceSection
//        }
//    }
//
//    var roleSection: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 8
//        ) {
//
//            Text("Choose Your Role")
//                .font(
//                    .system(
//                        size: 12,
//                        weight: .regular
//                    )
//                )
//                .foregroundStyle(Color.onboardingLabel)
//
//            rolePicker
//        }
//    }
//
//    var taskForceSection: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 8
//        ) {
//
//            Text("Which task force are you from?")
//                .font(
//                    .system(
//                        size: 12,
//                        weight: .regular
//                    )
//                )
//                .foregroundStyle(Color.onboardingLabel)
//
//            taskForcePicker
//        }
//    }
//}
//
//
//// MARK: - Role Picker
//
//private extension OnboardingView {
//
//    var rolePicker: some View {
//        Menu {
//
//            ForEach(viewModel.roles) { role in
//
//                Button {
//                    viewModel.selectedRole = role
//                } label: {
//
//                    if viewModel.selectedRole == role {
//
//                        Label(
//                            role.rawValue,
//                            systemImage: "checkmark"
//                        )
//
//                    } else {
//
//                        Text(role.rawValue)
//                    }
//                }
//            }
//
//        } label: {
//
//            pickerField(
//                title:
//                    viewModel.selectedRole?.rawValue
//                    ?? "Select your role",
//                isPlaceholder:
//                    viewModel.selectedRole == nil
//            )
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//
//// MARK: - Task Force Picker
//
//private extension OnboardingView {
//
//    var taskForcePicker: some View {
//        Menu {
//
//            ForEach(viewModel.taskForces) { taskForce in
//
//                Button {
//                    viewModel.selectedTaskForce = taskForce
//                } label: {
//
//                    if viewModel.selectedTaskForce == taskForce {
//
//                        Label(
//                            taskForce.rawValue,
//                            systemImage: "checkmark"
//                        )
//
//                    } else {
//
//                        Text(taskForce.rawValue)
//                    }
//                }
//            }
//
//        } label: {
//
//            pickerField(
//                title:
//                    viewModel.selectedTaskForce?.rawValue
//                    ?? "Select your task force",
//                isPlaceholder:
//                    viewModel.selectedTaskForce == nil
//            )
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//
//// MARK: - Picker Field
//
//private extension OnboardingView {
//
//    func pickerField(
//        title: String,
//        isPlaceholder: Bool
//    ) -> some View {
//
//        HStack {
//
//            Text(title)
//                .font(
//                    .system(
//                        size: 13,
//                        weight: .medium
//                    )
//                )
//                .foregroundStyle(
//                    isPlaceholder
//                    ? Color.onboardingPlaceholder
//                    : Color.onboardingText
//                )
//
//            Spacer()
//
//            Image(systemName: "chevron.down")
//                .font(
//                    .system(
//                        size: 10,
//                        weight: .medium
//                    )
//                )
//                .foregroundStyle(
//                    Color.onboardingChevron
//                )
//        }
//        .padding(.horizontal, 12)
//        .frame(height: 38)
//        .background(
//            Color.onboardingField
//        )
//        .clipShape(
//            RoundedRectangle(
//                cornerRadius: 10,
//                style: .continuous
//            )
//        )
//    }
//}
//
//
//// MARK: - Action
//
//private extension OnboardingView {
//
//    func handleNext() {
//
//        guard viewModel.canContinue else {
//            return
//        }
//
//        viewModel.continueOnboarding()
//
//        withAnimation(
//            .easeInOut(duration: 0.2)
//        ) {
//            hasCompletedOnboarding = true
//        }
//    }
//}
//
//
//// MARK: - Adaptive Colors
//
//private extension Color {
//
//    static let onboardingBackground = Color(
//        uiColor: .systemGroupedBackground
//    )
//
//    static let onboardingTitle = Color(
//        uiColor: .label
//    )
//
//    static let onboardingLabel = Color(
//        uiColor: .secondaryLabel
//    )
//
//    static let onboardingText = Color(
//        uiColor: .label
//    )
//
//    static let onboardingPlaceholder = Color(
//        uiColor: .tertiaryLabel
//    )
//
//    static let onboardingField = Color(
//        uiColor: .secondarySystemGroupedBackground
//    )
//
//    static let onboardingChevron = Color(
//        uiColor: .tertiaryLabel
//    )
//
//    static let onboardingButtonActive = Color(
//        red: 239 / 255,
//        green: 67 / 255,
//        blue: 67 / 255
//    )
//
//    static let onboardingButtonInactive = Color(
//        red: 239 / 255,
//        green: 67 / 255,
//        blue: 67 / 255
//    )
//    .opacity(0.45)
//}
//
//
//// MARK: - Preview
//
//#Preview("Light Mode") {
//    OnboardingView(
//        hasCompletedOnboarding: .constant(false)
//    )
//    .preferredColorScheme(.light)
//}
//
//#Preview("Dark Mode") {
//    OnboardingView(
//        hasCompletedOnboarding: .constant(false)
//    )
//    .preferredColorScheme(.dark)
//}
