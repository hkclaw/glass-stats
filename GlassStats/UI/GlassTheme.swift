import SwiftUI

enum GlassTheme {
    static let panelRadius: CGFloat = 16
    static let popoverWidth: CGFloat = 384
    static let accent = Color.cyan
}

extension View {
    /// Liquid Glass on macOS 26+ / Swift 6.2 SDKs; vibrancy material otherwise.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = GlassTheme.panelRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26.0, *) {
            self
                .padding(12)
                .glassEffect(.regular, in: shape)
        } else {
            legacyGlassCard(shape: shape)
        }
        #else
        legacyGlassCard(shape: shape)
        #endif
    }

    func legacyGlassCard(shape: RoundedRectangle) -> some View {
        self
            .padding(12)
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

    @ViewBuilder
    func glassPopoverChrome() -> some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26.0, *) {
            self
        } else {
            background(.ultraThinMaterial)
        }
        #else
        background(.ultraThinMaterial)
        #endif
    }

    @ViewBuilder
    func glassControlStyle() -> some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
        #else
        self.buttonStyle(.bordered)
        #endif
    }
}

struct GlassStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        #if compiler(>=6.2) || swift(>=6.2)
        if #available(macOS 26.0, *) {
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
