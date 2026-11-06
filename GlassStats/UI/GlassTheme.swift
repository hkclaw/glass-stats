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

    static let lightRim = LinearGradient(
        colors: [
            Color.white.opacity(0.98),
            Color(red: 0.42, green: 0.51, blue: 0.62).opacity(0.78),
            Color(red: 0.26, green: 0.34, blue: 0.44).opacity(0.62)
        ],
        startPoint: .top,
        endPoint: .bottom
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
                lightSystemGlass(content)
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
            lightMaterialCard(content)
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

    /// Brighter frosted card on the darker shell: material, white veil, specular lid, rim, shadow.
    private func lightMaterialCard(_ content: Content) -> some View {
        content
            .background {
                shape
                    .fill(.thinMaterial)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.58),
                                    Color.white.opacity(0.30)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.40),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    }
                    .overlay {
                        shape.strokeBorder(GlassTheme.lightRim, lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.16), radius: 7, y: 3)
            }
    }

    #if compiler(>=6.2) || swift(>=6.2)
    /// Separate glass piece: white tint, its own rim, and a shadow. Dark stays `.regular` with no extra chrome.
    @available(macOS 26, *)
    private func lightSystemGlass(_ content: Content) -> some View {
        content
            .glassEffect(
                .regular.tint(Color(red: 0.94, green: 0.97, blue: 1.0).opacity(0.55)),
                in: shape
            )
            .overlay {
                shape.strokeBorder(GlassTheme.lightRim, lineWidth: 1)
            }
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.14), radius: 7, y: 3)
    }
    #endif
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

    /// Cooler, deeper shell so frosted cards and white controls lift off it. Specular stays behind the type.
    private func lightShell(_ content: Content) -> some View {
        content.background {
            ZStack {
                Rectangle().fill(.regularMaterial)
                LinearGradient(
                    colors: [
                        Color(red: 0.63, green: 0.70, blue: 0.78).opacity(0.58),
                        Color(red: 0.50, green: 0.58, blue: 0.68).opacity(0.50)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.32),
                        Color.cyan.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.28)
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

/// White glass circle with a dark glyph and a real rim. System bordered buttons sit white-on-pale-gray.
private struct LightGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(
                Color(red: 0.12, green: 0.16, blue: 0.22)
                    .opacity(configuration.isPressed ? 0.55 : 0.94)
            )
            .frame(width: 30, height: 28)
            .background {
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.72 : 0.92))
                    .overlay {
                        Circle().strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.34, green: 0.42, blue: 0.52).opacity(0.72)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    }
                    .shadow(
                        color: Color.black.opacity(configuration.isPressed ? 0.06 : 0.16),
                        radius: 2,
                        y: 1
                    )
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
