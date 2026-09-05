import SwiftUI

enum GlassTheme {
    static let panelRadius: CGFloat = 16
    static let popoverWidth: CGFloat = 384
    static let accent = Color.cyan
}

extension View {
    /// Liquid Glass on macOS 26 via `#available(macOS 26, *)` + `.glassEffect`.
    /// Older OS (and older SDKs that lack the symbol) use `.ultraThinMaterial`.
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
}

private struct LiquidGlassBackground<S: Shape>: ViewModifier {
    var shape: S

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            materialFallback(content)
        }
        #else
        materialFallback(content)
        #endif
    }

    private func materialFallback(_ content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.strokeBorder(
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

private struct LiquidGlassChrome: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26, *) {
            content
        } else {
            content.background(.ultraThinMaterial)
        }
        #else
        content.background(.ultraThinMaterial)
        #endif
    }
}

private struct LiquidGlassControl: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
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

struct GlassStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 14) {
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
