//
//  BottomSheet.swift
//  hydrant
//

import SwiftUI

// A draggable bottom sheet that lives in the same view hierarchy
// as the map, so the map, top controls, and sheet content remain
// interactive at the same time.
struct BottomSheet<Content: View>: View {

    @Binding var isExpanded: Bool

    // Default collapsed fraction used as fallback.
    var collapsedFraction: CGFloat = 0.18
    var expandedFraction: CGFloat = 0.85

    @ViewBuilder var content: () -> Content

    @State private var contentHeight: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let maxScreenHeight =
                proxy.size.height * expandedFraction

            let minScreenHeight =
                proxy.size.height * 0.14

            // Dynamic collapsed height based on intrinsic content
            // measurement, including additional space for the grabber.
            let dynamicCollapsed =
                contentHeight > 0
                ? min(
                    max(
                        contentHeight + 26,
                        minScreenHeight
                    ),
                    maxScreenHeight
                )
                : proxy.size.height * collapsedFraction

            let base =
                isExpanded
                ? maxScreenHeight
                : dynamicCollapsed

            let height = min(
                max(
                    base - dragTranslation,
                    minScreenHeight
                ),
                maxScreenHeight
            )

            VStack(spacing: 0) {
                grabber
                content()
            }
            .frame(
                width: proxy.size.width,
                height: height,
                alignment: .top
            )
            .background(.regularMaterial)
            .clipShape(
                .rect(
                    topLeadingRadius: 24,
                    topTrailingRadius: 24
                )
            )
            .shadow(
                color: .black.opacity(0.18),
                radius: 12,
                y: -3
            )
            .background(
                // Hidden measurement view using fixedSize
                // to prevent layout oscillation.
                content()
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .hidden()
                    .background(
                        GeometryReader { measureProxy in
                            Color.clear
                                .onAppear {
                                    let newHeight =
                                        measureProxy.size.height

                                    if abs(
                                        contentHeight - newHeight
                                    ) > 2 {
                                        contentHeight = newHeight
                                    }
                                }
                                .onChange(
                                    of: measureProxy.size.height
                                ) { _, newHeight in
                                    if abs(
                                        contentHeight - newHeight
                                    ) > 2 {
                                        contentHeight = newHeight
                                    }
                                }
                        }
                    )
                    .allowsHitTesting(false)
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottom
            )
            .animation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.85
                ),
                value: isExpanded
            )
            .animation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.85
                ),
                value: contentHeight
            )
        }
        // Ignore only the device/container safe area.
        // The keyboard safe area remains respected.
        .ignoresSafeArea(
            .container,
            edges: .bottom
        )
    }

    // The drag handle: dragging or tapping it resizes the sheet.
    private var grabber: some View {
        Capsule()
            .fill(.secondary.opacity(0.6))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .updating(
                        $dragTranslation
                    ) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height < -40 {
                            isExpanded = true
                        } else if value.translation.height > 40 {
                            isExpanded = false
                        }
                    }
            )
            .onTapGesture {
                isExpanded.toggle()
            }
    }
}
