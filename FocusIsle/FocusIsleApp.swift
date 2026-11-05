import SwiftUI

@main
struct FocusIsleApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model).tint(IsleTheme.moss).preferredColorScheme(.light)
        }
    }
}

private enum GameTab: String, CaseIterable {
    case focus = "Focus", island = "Island", collection = "Collection", progress = "Progress", settings = "Settings"
    var sprite: String {
        switch self {
        case .focus: "clock"
        case .island: "pine"
        case .collection: "fern"
        case .progress: "chart"
        case .settings: "gear"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: GameTab = .focus
    var body: some View {
        Group {
            switch selectedTab {
            case .focus: FocusView { selectedTab = .settings }
            case .island: IslandView()
            case .collection: CollectionView()
            case .progress: ProgressViewScreen()
            case .settings: SettingsView(services: model.services)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                #if DEBUG
                if model.isTesting {
                    HStack {
                        Text("TEST ISLAND").font(.system(size: 10, weight: .bold, design: .monospaced))
                        Spacer()
                        Button("Exit test") { model.setTesting(false) }
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .disabled(model.state.activeSession != nil)
                    }.padding(.horizontal, 22).padding(.vertical, 9)
                        .foregroundStyle(IsleTheme.ink).background(IsleTheme.peach)
                }
                #endif
                navigation
            }
        }
        .foregroundStyle(IsleTheme.ink)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in model.tick() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.services.refreshStatus(); model.tick() }
        }
        .alert("Unable to complete action", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .sheet(isPresented: Binding(get: { model.rewardMessage != nil }, set: { if !$0 { model.rewardMessage = nil } })) {
            VStack(spacing: 22) {
                PixelSprite(id: "egg").frame(width: 80, height: 80)
                Text("Session complete").font(.system(size: 24, weight: .bold, design: .monospaced))
                Text(model.rewardMessage ?? "Session complete.").font(.system(size: 14, design: .monospaced)).multilineTextAlignment(.center).foregroundStyle(IsleTheme.secondary)
                Button("View island") { model.rewardMessage = nil; selectedTab = .island }.buttonStyle(IsleButton())
                Button("Continue") { model.rewardMessage = nil }.font(.system(size: 12, design: .monospaced))
            }.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity).background(IsleTheme.background)
                .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
    }

    private var navigation: some View {
        HStack(spacing: 4) {
            ForEach(GameTab.allCases, id: \.self) { tab in
                Button { selectedTab = tab } label: {
                    VStack(spacing: 5) {
                        PixelSprite(id: tab.sprite).frame(width: 25, height: 25)
                        Text(tab.rawValue).font(.system(size: 9, weight: selectedTab == tab ? .bold : .regular, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .foregroundStyle(selectedTab == tab ? IsleTheme.ink : IsleTheme.secondary)
                    .background(selectedTab == tab ? IsleTheme.moss.opacity(0.09) : .clear)
                    .overlay(alignment: .bottom) { if selectedTab == tab { Rectangle().fill(IsleTheme.moss).frame(height: 2) } }
                    .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 4)
        .background(IsleTheme.paper.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(IsleTheme.line).frame(height: 1) }
    }
}
