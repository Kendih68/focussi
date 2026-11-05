import SwiftUI

enum IsleTheme {
    static let ink = Color(hex: 0x293B43)
    static let moss = Color(hex: 0x397E70)
    static let cream = Color(hex: 0xF5F1E7)
    static let background = cream
    static let paper = Color(hex: 0xFFFCF4)
    static let water = Color(hex: 0xA9D3D1)
    static let peach = Color(hex: 0xE8B66D)
    static let secondary = Color(hex: 0x697875)
    static let line = Color(hex: 0xD8D6C7)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
}

struct PaperCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(IsleTheme.paper)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(IsleTheme.line, lineWidth: 1))
    }
}

struct IsleButton: ButtonStyle {
    var secondary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15, weight: .bold, design: .monospaced))
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(secondary ? IsleTheme.ink : IsleTheme.paper)
            .background(secondary ? IsleTheme.paper : IsleTheme.moss)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(IsleTheme.ink.opacity(0.5), lineWidth: 1))
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SectionLabel: View {
    var title: String
    var detail: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased()).font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1)
            Spacer()
            if let detail { Text(detail).font(.system(size: 11, design: .monospaced)).foregroundStyle(IsleTheme.secondary) }
        }
    }
}

struct HatchProgress: View {
    var progress: Int
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<4) { index in
                Rectangle().fill(index < progress ? IsleTheme.moss : IsleTheme.line.opacity(0.45))
                    .frame(height: 6)
                    .overlay(Rectangle().strokeBorder(IsleTheme.ink.opacity(0.15), lineWidth: 0.5))
            }
        }.accessibilityLabel("\(progress) of 4 focus sessions completed")
    }
}

struct GamePage<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            ScrollView {
                content.padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 24)
            }
            .background(IsleTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text(title.uppercased()).font(.system(size: 14, weight: .bold, design: .monospaced)).tracking(1) } }
            .toolbarBackground(IsleTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
