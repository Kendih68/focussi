import SwiftUI
import FocusCore

@MainActor
final class AppModel: ObservableObject {
    @Published var state: FocusCore.FocusState
    @Published var error: String?
    @Published var rewardMessage: String?
    let services = FocusServices()
    private let store: StateStore
    #if DEBUG
    @Published private(set) var isTesting = false
    private var testStore: StateStore {
        StateStore(fileURL: store.fileURL.deletingLastPathComponent().appendingPathComponent("test-progress.json"))
    }
    #endif

    private var currentStore: StateStore {
        #if DEBUG
        if isTesting { return testStore }
        #endif
        return store
    }

    private var usesDeviceServices: Bool {
        #if DEBUG
        if isTesting { return false }
        #endif
        return true
    }

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        store = StateStore(fileURL: folder.appendingPathComponent("FocusIsle/progress.json"))
        do { state = try store.load() }
        catch {
            state = FocusCore.FocusState()
            self.error = "Your saved island could not be read. \(error.localizedDescription)"
        }
        tick()
    }

    func tick() {
        if let reward = state.completeIfDue(now: Date(), calendar: .current) {
            services.endFocus()
            services.cancelNotification()
            if reward.kind == .focus {
                var message = "+\(reward.materials) materials for your island."
                if let creature = reward.creature { message += " \(creature.name) hatched." }
                if !reward.milestones.isEmpty { message += " A new streak keepsake is yours." }
                rewardMessage = message
            } else {
                rewardMessage = "Break complete. Start your next focus session whenever you’re ready."
            }
            save()
        }
        services.reconcile(activeDeadline: state.activeSession?.kind == .focus ? state.activeSession?.endsAt : nil)
    }

    func start() {
        guard state.activeSession == nil else { return }
        let previous = state
        state.start(now: Date())
        guard let session = state.activeSession else { return }
        do {
            if usesDeviceServices && session.kind == .focus && services.selectedCount > 0 { try services.beginFocus(until: session.endsAt) }
            try currentStore.save(state)
            if usesDeviceServices { services.scheduleNotification(until: session.endsAt, isFocus: session.kind == .focus) }
        } catch {
            state = previous
            services.endFocus()
            self.error = error.localizedDescription
        }
    }

    func endEarly() {
        let before = state.totalSessions
        _ = state.endEarly(now: Date(), calendar: .current)
        services.endFocus()
        services.cancelNotification()
        if state.totalSessions > before { rewardMessage = "Session complete. Your island has earned new materials." }
        save()
    }

    func purchase(_ decoration: Decoration) {
        if state.purchase(decoration) { save() }
    }

    func save() {
        do { try currentStore.save(state) }
        catch { self.error = "Couldn’t save your island: \(error.localizedDescription)" }
    }

    #if DEBUG
    func setTesting(_ enabled: Bool) {
        guard state.activeSession == nil, enabled != isTesting else { return }
        do {
            try currentStore.save(state)
            let restored = try (enabled ? testStore : store).load()
            isTesting = enabled
            state = restored
            rewardMessage = nil
            tick()
        } catch { self.error = "Couldn’t switch islands: \(error.localizedDescription)" }
    }

    func addTestMaterials() {
        guard isTesting, state.activeSession == nil else { return }
        state.debugGrantMaterials()
        save()
    }

    func simulateFocusSessions(_ count: Int) {
        guard isTesting, state.activeSession == nil else { return }
        for _ in 0..<min(4, max(0, count)) {
            state.debugCompleteFocus(now: Date(), calendar: .current)
        }
        save()
    }
    #endif
}
