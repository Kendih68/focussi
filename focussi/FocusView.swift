import SwiftUI
import FocusCore

struct FocusView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmEnd = false
    @ScaledMetric(relativeTo: .largeTitle) private var timerSize = 76.0
    var onOpenSettings: () -> Void = {}
    private var active: Bool { model.state.activeSession != nil }
    private var kind: SessionKind { model.state.activeSession?.kind ?? model.state.nextKind }

    var body: some View {
        NavigationStack {
            GeometryReader { layout in
            ScrollView {
                VStack(spacing: layout.size.height < 620 ? 14 : 20) {
                    HStack {
                        Label("\(model.state.currentStreak(now: Date(), calendar: .current)) DAY STREAK", systemImage: "flame")
                        Spacer()
                        Text("◆ \(model.state.materials)").foregroundStyle(IsleTheme.moss)
                            .accessibilityLabel("\(model.state.materials) materials")
                    }.font(.system(size: 11, weight: .semibold, design: .monospaced))

                    if !active {
                        IslandScene(decorations: model.state.purchasedDecorations, creatures: model.state.creaturesHatched, compact: true, milestones: model.state.unlockedMilestones)
                            .frame(height: layout.size.height < 620 ? 116 : 188)
                            .overlay(alignment: .topLeading) {
                                Text("YOUR CAMPSITE").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1)
                                    .foregroundStyle(IsleTheme.ink.opacity(0.65)).padding(12)
                            }
                            .overlay(Rectangle().strokeBorder(IsleTheme.ink.opacity(0.2), lineWidth: 1))
                    } else {
                        PixelSprite(id: kind == .focus ? "pine" : "clock").frame(width: 64, height: 64).padding(.top, 28)
                    }

                    VStack(spacing: 18) {
                        if !active { sessionSelector }
                        VStack(spacing: 3) {
                            if active {
                                Text(kind.title.uppercased()).font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1.5)
                                    .foregroundStyle(IsleTheme.secondary)
                            }
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text(timeText(at: context.date))
                                    .font(.system(size: min(timerSize, layout.size.height < 620 ? 66 : 108), weight: .regular, design: .monospaced))
                                    .tracking(-5).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                                    .contentTransition(.numericText())
                                    .accessibilityLabel("\(remaining(at: context.date) / 60) minutes, \(remaining(at: context.date) % 60) seconds remaining")
                            }.frame(maxWidth: .infinity)
                            if let session = model.state.activeSession {
                                Text("ENDS AT \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                            } else {
                                Text(kind == .focus ? "+10 MATERIALS ON COMPLETION" : "APPS STAY UNLOCKED")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                            }
                        }.padding(.vertical, active ? 22 : 0)
                        if active {
                            Button("End session") { confirmEnd = true }.buttonStyle(IsleButton(secondary: true))
                        } else {
                            Button { model.start() } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill").font(.system(size: 12))
                                    Text(kind == .focus ? "Start focus" : "Start break")
                                }
                            }.buttonStyle(IsleButton())
                        }
                    }
                    FocusProtectionSummary(services: model.services, active: active, onBreak: active && kind != .focus, onOpenSettings: onOpenSettings)
                    if !active {
                        Divider().overlay(IsleTheme.line)
                        HStack(spacing: 14) {
                            PixelSprite(id: "egg").frame(width: 38, height: 38)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("NEXT HATCH").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                                    Spacer()
                                    Text("\(model.state.creatureProgress) / 4").font(.system(size: 11, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                                }
                                HatchProgress(progress: model.state.creatureProgress)
                                Text("\(model.state.nextCreature.name) · \(4 - model.state.creatureProgress) sessions left")
                                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                            }
                        }
                    }
                    if active {
                        Text(kind == .focus ? "Finish this session to earn 10 materials." : "Start your next session when you’re ready.")
                            .font(.system(size: 12, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                            .multilineTextAlignment(.center).padding(.top, 12)
                    }
                }.padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 24)
            }
            }
            .background(IsleTheme.background)
            .navigationTitle("focussi").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("focussi").font(.system(size: 14, weight: .bold, design: .monospaced)).tracking(2) } }
            .toolbarBackground(IsleTheme.background, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("End this session?", isPresented: $confirmEnd, titleVisibility: .visible) {
                Button("End session", role: .destructive) { model.endEarly() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text(kind == .focus ? "Your apps will unlock, but you won’t earn a reward. Previously earned rewards and streak credit stay safe." : "Your break will end. You can start your next session when you’re ready.")
            }
        }
    }

    private var sessionSelector: some View {
        HStack(spacing: 0) {
            ForEach(SessionKind.allCases, id: \.self) { mode in
                Button {
                    model.state.select(mode); model.save()
                } label: {
                    Text(mode == .focus ? "Focus" : mode == .shortBreak ? "Short break" : "Long break")
                        .font(.system(size: 11, weight: kind == mode ? .bold : .regular, design: .monospaced))
                        .frame(maxWidth: .infinity).frame(minHeight: 38)
                        .foregroundStyle(kind == mode ? IsleTheme.paper : IsleTheme.secondary)
                        .background(kind == mode ? IsleTheme.ink : .clear)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityAddTraits(kind == mode ? .isSelected : [])
            }
        }.padding(3).overlay(Rectangle().strokeBorder(IsleTheme.line, lineWidth: 1))
    }

    private func timeText(at date: Date) -> String {
        let seconds = remaining(at: date)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    private func remaining(at date: Date) -> Int {
        if let session = model.state.activeSession { return max(0, Int(ceil(session.endsAt.timeIntervalSince(date)))) }
        return model.state.settings.minutes(for: kind) * 60
    }
}

struct FocusProtectionSummary: View {
    @ObservedObject var services: FocusServices
    var active = false
    var onBreak = false
    var onOpenSettings: () -> Void = {}
    var body: some View {
        #if SCREEN_TIME_ENABLED
        Button(action: onOpenSettings) {
            HStack(spacing: 7) {
                Image(systemName: services.selectedCount > 0 && services.authorizationStatus == .approved ? "shield.lefthalf.filled" : "shield")
                Text(status).multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
            }.font(.system(size: 10, design: .monospaced)).foregroundStyle(IsleTheme.secondary).frame(minHeight: 32)
        }.buttonStyle(.plain).accessibilityHint("Open app blocking settings")
        #else
        Text(onBreak ? "Break · apps stay unlocked" : "Timer only · app blocking not included")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(IsleTheme.secondary).frame(minHeight: 32)
        #endif
    }
    private var status: String {
        #if SCREEN_TIME_ENABLED
        if onBreak { return "Break · apps are unlocked" }
        if services.selectedCount == 0 { return "Timer only · choose apps to block" }
        if services.authorizationStatus != .approved { return "App blocking needs permission" }
        return active ? "\(services.selectedCount) selections · blocking enabled" : "\(services.selectedCount) selections ready to block"
        #else
        return "Timer only"
        #endif
    }
}
