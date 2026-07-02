//
//  UploadSpeedWidgetView.swift
//  SwiftUIPages
//
//  Interactive demo for the glassmorphism upload-speed widget.
//

import SwiftUI

struct UploadSpeedWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 10 / 255, green: 13 / 255, blue: 24 / 255),
                Color(red: 18 / 255, green: 24 / 255, blue: 42 / 255),
                Color(red: 13 / 255, green: 16 / 255, blue: 32 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [
                    UploadSpeedWidgetStyle.cyan.opacity(0.08),
                    .clear,
                ],
                center: UnitPoint(x: 0.2, y: 0.1),
                startRadius: 0,
                endRadius: 420
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    UploadSpeedWidgetStyle.purple.opacity(0.1),
                    .clear,
                ],
                center: UnitPoint(x: 0.85, y: 0.9),
                startRadius: 0,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

struct UploadSpeedWidgetView: View {
    @State private var speed: Double = 42.8
    @State private var isAnimating = true
    @State private var glowIntensity: CGFloat = 0.65
    @State private var simulationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            UploadSpeedWidgetBackground()

            VStack(spacing: 28) {
                UploadSpeedWidget(
                    speed: speed,
                    isAnimating: isAnimating,
                    glowIntensity: glowIntensity
                )
                .scaleEffect(isAnimating ? 1 : 0.97)
                .animation(.easeInOut(duration: 0.35), value: isAnimating)
                .onTapGesture {
                    toggleAnimation()
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("双击以暂停或恢复动画")

                Text(isAnimating ? "点击小组件 · 暂停动画与速度模拟" : "已暂停 · 点击恢复")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .navigationTitle("Upload Widget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            startGlowPulse()
            startSimulation()
        }
        .onDisappear {
            simulationTask?.cancel()
            simulationTask = nil
        }
    }

    private func toggleAnimation() {
        isAnimating.toggle()
        if isAnimating {
            glowIntensity = 0.65
            startGlowPulse()
            startSimulation()
        } else {
            simulationTask?.cancel()
            simulationTask = nil
            withAnimation(.easeInOut(duration: 0.35)) {
                glowIntensity = 0.4
            }
        }
    }

    private func startGlowPulse() {
        guard isAnimating else { return }
        glowIntensity = 0.65
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
            glowIntensity = 0.95
        }
    }

    private func startSimulation() {
        simulationTask?.cancel()
        simulationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(900))
                guard !Task.isCancelled else { continue }

                let shouldContinue = await MainActor.run { isAnimating }
                guard shouldContinue else { continue }

                await MainActor.run {
                    let delta = Double.random(in: -0.6 ... 0.6)
                    speed = min(99.9, max(8, speed + delta))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadSpeedWidgetView()
    }
}
