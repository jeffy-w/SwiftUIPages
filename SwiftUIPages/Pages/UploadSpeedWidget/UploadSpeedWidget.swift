//
//  UploadSpeedWidget.swift
//  SwiftUIPages
//
//  Glassmorphism upload-speed widget (iOS small-widget style).
//

import SwiftUI

enum UploadSpeedWidgetStyle {
    static let size: CGFloat = 170
    static let cornerRadius: CGFloat = 38
    static let borderWidth: CGFloat = 1.5

    static let cyan = Color(red: 160 / 255, green: 233 / 255, blue: 255 / 255)
    static let cyanBright = Color(red: 200 / 255, green: 244 / 255, blue: 255 / 255)
    static let purple = Color(red: 196 / 255, green: 181 / 255, blue: 253 / 255)
    static let purpleSoft = Color(red: 212 / 255, green: 201 / 255, blue: 255 / 255)
    static let labelMuted = Color(red: 210 / 255, green: 235 / 255, blue: 255 / 255).opacity(0.82)
    static let unit = Color(red: 160 / 255, green: 233 / 255, blue: 255 / 255).opacity(0.72)
    static let glassFill = Color(red: 18 / 255, green: 22 / 255, blue: 38 / 255).opacity(0.62)
    static let glassOverlay = Color(red: 12 / 255, green: 16 / 255, blue: 30 / 255).opacity(0.45)

    static var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                cyan,
                Color(red: 142 / 255, green: 216 / 255, blue: 248 / 255),
                purple,
                purpleSoft,
                cyan,
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    static var glowGradient: LinearGradient {
        LinearGradient(
            colors: [
                cyan.opacity(0.55),
                purple.opacity(0.45),
                cyan.opacity(0.35),
            ],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    static var widgetShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    static var innerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius - borderWidth, style: .continuous)
    }
}

struct UploadSpeedWidget: View {
    let speed: Double
    var isAnimating: Bool = true
    var glowIntensity: CGFloat = 1

    var body: some View {
        ZStack {
            UploadSpeedWidgetStyle.widgetShape
                .stroke(UploadSpeedWidgetStyle.glowGradient, lineWidth: 3)
                .blur(radius: 14)
                .opacity((isAnimating ? 0.65 : 0.4) * glowIntensity)
                .padding(-6)

            UploadSpeedWidgetStyle.widgetShape
                .fill(UploadSpeedWidgetStyle.borderGradient)
                .overlay {
                    ZStack {
                        UploadSpeedWidgetStyle.innerShape
                            .fill(UploadSpeedWidgetStyle.glassFill)

                        UploadSpeedWidgetStyle.innerShape
                            .fill(.ultraThinMaterial)
                            .opacity(0.55)

                        UploadSpeedWidgetStyle.innerShape
                            .fill(
                                RadialGradient(
                                    colors: [
                                        UploadSpeedWidgetStyle.cyan.opacity(0.07),
                                        .clear,
                                    ],
                                    center: .top,
                                    startRadius: 0,
                                    endRadius: UploadSpeedWidgetStyle.size * 0.55
                                )
                            )

                        UploadSpeedWidgetStyle.innerShape
                            .fill(
                                RadialGradient(
                                    colors: [
                                        UploadSpeedWidgetStyle.purple.opacity(0.06),
                                        .clear,
                                    ],
                                    center: .bottomTrailing,
                                    startRadius: 0,
                                    endRadius: UploadSpeedWidgetStyle.size * 0.45
                                )
                            )

                        UploadSpeedWidgetStyle.innerShape
                            .fill(UploadSpeedWidgetStyle.glassOverlay)
                    }
                    .padding(UploadSpeedWidgetStyle.borderWidth)
                }
                .clipShape(UploadSpeedWidgetStyle.widgetShape)

            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.square.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(UploadSpeedWidgetStyle.cyan)
                        .shadow(color: UploadSpeedWidgetStyle.cyan.opacity(0.6), radius: 4)

                    Text("Upload")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(UploadSpeedWidgetStyle.labelMuted)
                }
                .padding(.bottom, 6)

                Text(speed, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 52, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(UploadSpeedWidgetStyle.cyanBright)
                    .modifier(SpeedNeonGlow(active: isAnimating, intensity: glowIntensity))
                    .padding(.vertical, 2)

                Text("Mbps")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(UploadSpeedWidgetStyle.unit)
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
        .frame(
            width: UploadSpeedWidgetStyle.size,
            height: UploadSpeedWidgetStyle.size
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Upload \(speed.formatted(.number.precision(.fractionLength(1)))) Mbps")
    }
}

private struct SpeedNeonGlow: ViewModifier {
    let active: Bool
    let intensity: CGFloat

    func body(content: Content) -> some View {
        let cyan = UploadSpeedWidgetStyle.cyan
        let scale = active ? intensity : 0.5

        content
            .shadow(color: cyan.opacity(0.95 * scale), radius: 4)
            .shadow(color: cyan.opacity(0.65 * scale), radius: 9)
            .shadow(color: cyan.opacity(0.35 * scale), radius: 18)
            .shadow(color: cyan.opacity(0.15 * scale), radius: 30)
    }
}

#Preview {
    ZStack {
        UploadSpeedWidgetBackground()
        UploadSpeedWidget(speed: 42.8)
    }
}
