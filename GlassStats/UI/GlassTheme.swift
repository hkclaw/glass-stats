import SwiftUI

enum GlassTheme {
    static let panelRadius: CGFloat = 16
    static let popoverWidth: CGFloat = 384
    static let popoverMaxHeight: CGFloat = 560

    /// Dark popover accent. Light surfaces use `cpuTint(_:)`, a deeper cyan that still reads on white.
    static let accent = Color.cyan

    /// System cyan is about 2.5:1 on white, so a hairline sparkline disappears. Dark keeps `accent`.
    static func cpuTint(_ scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.00, green: 0.45, blue: 0.65) : accent
    }

    /// Deeper teal in the same family as `Color.mint`, matched in contrast to the light CPU tint.
    static func memoryTint(_ scheme: ColorScheme) -> Color {
        scheme == .light ? Color(red: 0.00, green: 0.48, blue: 0.44) : .mint
    }

    /// One opaque face for every light card. Translucent glass was sampling the chart
    /// wash, so CPU cards went blue and memory cards went mint while process cards stayed white.
    static let lightCardSurface = Color(red: 0.980, green: 0.982, blue: 0.984)

    /// Specular top edge and a neutral hairline. Same job as the dark stroke, without a blue rim.
    static let lightRim = LinearGradient(
        colors: [
            Color.white.opacity(0.92),
            Color.black.opacity(0.08),
            Color.black.opacity(0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    /// Liquid Glass on macOS 26 via `#available(macOS 26, *)` + `.glassEffect`.
    /// Older OS (and older SDKs that lack the symbol) use a material fallback.
    func glassCard(cornerRadius: CGFloat = GlassTheme.panelRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .padding(12)
            .modifier(LiquidGlassBackground(shape: shape))
    }

    func glassPopoverChrome() -> some View {
        modifier(LiquidGlassChrome())
    }

    func glassControlStyle() -> some View {
        modifier(LiquidGlassControl())
    }

    func glassSecondaryText() -> some View {
        modifier(AdaptiveGlassText(opacity: 0.66))
    }

    func glassCaptionText() -> some View {
        modifier(AdaptiveGlassText(opacity: 0.62))
    }
}

/// Dark keeps hierarchical `.secondary` (vibrancy on the material). Light uses black at `opacity`:
/// system secondary is only about 3.5:1 on white, while the dark theme's muted text is about 6.6:1.
private struct AdaptiveGlassText: ViewModifier {
    var opacity: Double
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.foregroundStyle(Color.primary.opacity(opacity))
        } else {
            content.foregroundStyle(.secondary)
        }
    }
}

private struct LiquidGlassBackground<S: InsettableShape>: ViewModifier {
    var shape: S
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26, *) {
            if colorScheme == .light {
                neutralLightCard(content)
            } else {
                content.glassEffect(.regular, in: shape)
            }
        } else {
            materialFallback(content)
        }
        #else
        materialFallback(content)
        #endif
    }

    @ViewBuilder
    private func materialFallback(_ content: Content) -> some View {
        if colorScheme == .light {
            neutralLightCard(content)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.cyan.opacity(0.12),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                }
        }
    }

    /// Identical neutral face on every light card, including macOS 26. `.glassEffect` refracts
    /// the chart wash into the title row, so light cards do not use it. Dark still does.
    private func neutralLightCard(_ content: Content) -> some View {
        content
            .background {
                shape
                    .fill(GlassTheme.lightCardSurface)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: UnitPoint(x: 0.5, y: 0.22)
                            )
                        )
                    }
                    .overlay {
                        shape.strokeBorder(GlassTheme.lightRim, lineWidth: 0.75)
                    }
            }
    }
}

private struct LiquidGlassChrome: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26, *) {
            if colorScheme == .light {
                lightShell(content)
            } else {
                content
            }
        } else {
            materialFallback(content)
        }
        #else
        materialFallback(content)
        #endif
    }

    @ViewBuilder
    private func materialFallback(_ content: Content) -> some View {
        if colorScheme == .light {
            lightShell(content)
        } else {
            content.background(.ultraThinMaterial)
        }
    }

    /// Neutral material, a step darker than the cards. No slate or cyan wash — that paint
    /// showed through the glass and turned every card the same pastel blue.
    private func lightShell(_ content: Content) -> some View {
        content.background {
            ZStack {
                Rectangle().fill(.thinMaterial)
                Color.black.opacity(0.045)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.18)
                )
            }
        }
    }
}

private struct LiquidGlassControl: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.buttonStyle(LightGlassButtonStyle())
        } else {
            #if compiler(>=6.2) || swift(>=6.2)
            if #available(macOS 26, *) {
                content.buttonStyle(.glass)
            } else {
                content.buttonStyle(.bordered)
            }
            #else
            content.buttonStyle(.bordered)
            #endif
        }
    }
}

/// Frosted circle in the same family as the cards. A hairline only — a drop shadow reads as a floating halo.
private struct LightGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(
                Color(red: 0.12, green: 0.16, blue: 0.22)
                    .opacity(configuration.isPressed ? 0.55 : 0.92)
            )
            .frame(width: 30, height: 28)
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Circle().fill(Color.white.opacity(configuration.isPressed ? 0.45 : 0.62))
                    }
                    .overlay {
                        Circle().strokeBorder(Color.primary.opacity(0.16), lineWidth: 0.75)
                    }
            }
            .contentShape(Circle())
    }
}

struct GlassStack<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26, *) {
            // Cards are 12pt apart. Container spacing of 14 merges their highlights into one sheet.
            // Light mode keeps each card's own specular edge. Dark stays at 14.
            GlassEffectContainer(spacing: colorScheme == .light ? 0 : 14) {
                VStack(alignment: .leading, spacing: 12, content: content)
            }
        } else {
            VStack(alignment: .leading, spacing: 12, content: content)
        }
        #else
        VStack(alignment: .leading, spacing: 12, content: content)
        #endif
    }
}
