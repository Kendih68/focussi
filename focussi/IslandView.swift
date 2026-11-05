import SwiftUI
import FocusCore

struct IslandView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        GamePage(title: "Island") {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("CAMPSITE").font(.system(size: 12, weight: .bold, design: .monospaced)).tracking(1)
                    Spacer()
                    Text("◆ \(model.state.materials)").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(IsleTheme.moss)
                        .accessibilityLabel("\(model.state.materials) materials available")
                }
                IslandScene(decorations: model.state.purchasedDecorations, creatures: model.state.creaturesHatched, milestones: model.state.unlockedMilestones)
                    .aspectRatio(192.0 / 112.0, contentMode: .fit)
                    .overlay(Rectangle().strokeBorder(IsleTheme.ink.opacity(0.2), lineWidth: 1))
                HStack {
                    Text("\(model.state.purchasedDecorations.count) decorations placed")
                    Spacer()
                    Text("\(model.state.discoveredCreatures.count) / 6 creatures")
                }.font(.system(size: 10, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                Divider().overlay(IsleTheme.line)
                SectionLabel(title: "Build", detail: "+10 materials / session")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                    ForEach(Catalog.decorations) { item in
                        let owned = model.state.purchasedDecorations.contains(item.id)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                PixelSprite(id: item.id).frame(width: 56, height: 56)
                                Spacer()
                                if owned { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(IsleTheme.moss) }
                            }
                            Text(item.name).font(.system(size: 12, weight: .semibold, design: .monospaced)).lineLimit(2).frame(minHeight: 30, alignment: .bottomLeading)
                            Button { model.purchase(item) } label: {
                                Text(owned ? "Placed" : "◆ \(item.cost) · Place")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .frame(maxWidth: .infinity).frame(minHeight: 36)
                                    .background(owned ? IsleTheme.line.opacity(0.3) : IsleTheme.moss.opacity(0.10))
                                    .overlay(Rectangle().strokeBorder(IsleTheme.line, lineWidth: 1))
                            }.buttonStyle(.plain)
                                .disabled(owned || model.state.materials < item.cost)
                                .opacity(!owned && model.state.materials < item.cost ? 0.45 : 1)
                                .accessibilityLabel(owned ? "\(item.name), placed" : "Place \(item.name) for \(item.cost) materials")
                        }.padding(14).background(IsleTheme.paper).overlay(Rectangle().strokeBorder(IsleTheme.line, lineWidth: 1))
                    }
                }
                Text("Decorations are placed automatically and stay on your island.")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
            }
        }
    }
}

struct CollectionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        GamePage(title: "Collection") {
            VStack(alignment: .leading, spacing: 22) {
                PaperCard {
                    HStack(spacing: 14) {
                        PixelSprite(id: "egg").frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 9) {
                            SectionLabel(title: "Next: \(model.state.nextCreature.name)", detail: "\(model.state.creatureProgress)/4")
                            HatchProgress(progress: model.state.creatureProgress)
                            Text("\(4 - model.state.creatureProgress) focus sessions to hatch")
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                        }
                    }
                }
                SectionLabel(title: "Creatures", detail: "\(model.state.discoveredCreatures.count) / 6 found")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: typeSize.isAccessibilitySize ? 2 : 3), spacing: 10) {
                    ForEach(Catalog.creatures) { creature in
                        let found = model.state.discoveredCreatures.contains(where: { $0.id == creature.id })
                        VStack(spacing: 9) {
                            PixelSprite(id: creature.id).frame(width: 52, height: 52)
                                .saturation(found ? 1 : 0).opacity(found ? 1 : 0.28)
                            Text(creature.name).font(.system(size: 12, weight: .bold, design: .monospaced))
                            Text(found ? "DISCOVERED" : "\(creature.sessionsRequired) SESSIONS")
                                .font(.system(size: 8, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(found ? IsleTheme.paper : IsleTheme.line.opacity(0.15))
                            .overlay(Rectangle().strokeBorder(found ? IsleTheme.moss.opacity(0.45) : IsleTheme.line, lineWidth: 1))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(creature.name), \(found ? "discovered" : "unlocks at \(creature.sessionsRequired) sessions")")
                    }
                }
                Text("Hatch progress carries across days. Collected creatures are yours to keep.")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                Divider().overlay(IsleTheme.line)
                SectionLabel(title: "Streak keepsakes")
                VStack(spacing: 0) {
                    ForEach([3, 7, 14, 30], id: \.self) { days in
                        let earned = model.state.unlockedMilestones.contains(days)
                        HStack(spacing: 14) {
                            PixelSprite(id: milestoneSprite(days)).frame(width: 32, height: 32).opacity(earned ? 1 : 0.35)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(milestoneName(days)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("\(days)-day streak").font(.system(size: 10, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                            }
                            Spacer()
                            Image(systemName: earned ? "checkmark" : "lock").font(.system(size: 12)).foregroundStyle(earned ? IsleTheme.moss : IsleTheme.secondary)
                        }.padding(.vertical, 12)
                        if days != 30 { Divider().overlay(IsleTheme.line) }
                    }
                }
                SectionLabel(title: "Decorations", detail: "\(model.state.purchasedDecorations.count) / 6 owned")
                ForEach(Catalog.decorations) { item in
                    HStack(spacing: 12) {
                        PixelSprite(id: item.id).frame(width: 32, height: 32)
                        Text(item.name).font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text(model.state.purchasedDecorations.contains(item.id) ? "Owned" : "◆ \(item.cost)")
                            .font(.system(size: 10, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                    }
                }
            }
        }
    }
    private func milestoneSprite(_ days: Int) -> String {
        days == 3 ? "flowers" : days == 7 ? "lantern" : days == 14 ? "gateway" : "rainbow"
    }
    private func milestoneName(_ days: Int) -> String {
        days == 3 ? "Blossom patch" : days == 7 ? "Warm lantern" : days == 14 ? "Quiet gateway" : "Island rainbow"
    }
}
