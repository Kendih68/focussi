import Foundation
import FocusCore

struct FocusCoreTests {
    var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        return value
    }
    func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }
    @discardableResult func finish(_ state: inout FocusState, at start: Date) -> CompletionReward? {
        state.select(.focus)
        state.start(now: start)
        return state.completeIfDue(now: start.addingTimeInterval(25 * 60), calendar: calendar)
    }

    func deadlineSurvivesRelaunchAndAwardsOnlyOnce() throws {
        var state = FocusState()
        let start = date("2026-11-03T10:00:00+07:00")
        expect(state.start(now: start))
        expect(!state.start(now: start))
        var restored = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
        expect(restored.completeIfDue(now: start.addingTimeInterval(1499), calendar: calendar) == nil)
        expect(restored.completeIfDue(now: start.addingTimeInterval(3000), calendar: calendar)?.materials == 10)
        expect(restored.completeIfDue(now: start.addingTimeInterval(3001), calendar: calendar) == nil)
        expect(restored.totalSessions == 1)
        expect(restored.totalFocusMinutes == 25)
        expect(restored.activeSession == nil)
        expect(restored.nextKind == .shortBreak)
    }

    func earlyEndPreservesEarlierRewardsAndStreak() {
        var state = FocusState()
        let start = date("2026-11-03T10:00:00+07:00")
        finish(&state, at: start)
        state.select(.focus)
        state.start(now: start.addingTimeInterval(4000))
        expect(state.endEarly(now: start.addingTimeInterval(4010), calendar: calendar) == nil)
        expect(state.materials == 10)
        expect(state.totalSessions == 1)
        expect(state.currentStreak(now: start, calendar: calendar) == 1)
        expect(state.activeSession == nil)
    }

    func endingAtDeadlineCompletesInsteadOfForfeiting() {
        var state = FocusState()
        let start = date("2026-11-03T10:00:00+07:00")
        state.start(now: start)
        expect(state.endEarly(now: start.addingTimeInterval(1500), calendar: calendar)?.materials == 10)
        expect(state.totalSessions == 1)
    }

    func fourthFocusHatchesCreatureAndSuggestsLongBreak() {
        var state = FocusState()
        let start = date("2026-11-01T10:00:00+07:00")
        for day in 0..<3 {
            expect(finish(&state, at: start.addingTimeInterval(Double(day) * 86400))?.creature == nil)
        }
        let reward = finish(&state, at: start.addingTimeInterval(3 * 86400))
        expect(reward?.creature?.id == "fern")
        expect(state.creaturesHatched == 1)
        expect(state.creatureProgress == 0)
        expect(state.nextKind == .longBreak)
        expect(state.activeSession == nil)
        state.start(now: start.addingTimeInterval(3 * 86400 + 2000))
        expect(state.activeSession?.duration == 900)
        let breakReward = state.completeIfDue(now: start.addingTimeInterval(3 * 86400 + 2900), calendar: calendar)
        expect(breakReward?.kind == .longBreak)
        expect(state.materials == 40)
        expect(state.totalSessions == 4)
        expect(state.nextKind == .focus)
        expect(state.activeSession == nil)
    }

    func midnightCreditUsesFinishDateEvenAfterLateReopen() {
        var state = FocusState()
        let start = date("2026-11-03T23:50:00+07:00")
        state.start(now: start)
        state.completeIfDue(now: date("2026-11-06T10:00:00+07:00"), calendar: calendar)
        expect(state.completedSessions.first?.day.key == "2026-11-04")
        expect(state.currentStreak(now: date("2026-11-04T10:00:00+07:00"), calendar: calendar) == 1)
        expect(state.currentStreak(now: date("2026-11-05T10:00:00+07:00"), calendar: calendar) == 1)
        expect(state.currentStreak(now: date("2026-11-06T10:00:00+07:00"), calendar: calendar) == 0)
    }

    func multipleSessionsNeverAddExtraStreakDaysAndMissingDayResets() {
        var state = FocusState()
        finish(&state, at: date("2026-11-01T10:00:00+07:00"))
        finish(&state, at: date("2026-11-01T11:00:00+07:00"))
        finish(&state, at: date("2026-11-02T10:00:00+07:00"))
        expect(state.currentStreak(now: date("2026-11-02T12:00:00+07:00"), calendar: calendar) == 2)
        finish(&state, at: date("2026-11-04T10:00:00+07:00"))
        expect(state.currentStreak(now: date("2026-11-04T12:00:00+07:00"), calendar: calendar) == 1)
        expect(state.longestStreak() == 2)
        expect(state.totalSessions == 4)
    }

    func milestonesUnlockOnceAndRemainAfterMissedDay() {
        var state = FocusState()
        for day in 1...7 {
            finish(&state, at: date(String(format: "2026-11-%02dT10:00:00+07:00", day)))
        }
        expect(state.unlockedMilestones == [3, 7])
        expect(finish(&state, at: date("2026-11-07T11:00:00+07:00"))?.milestones == [])
        finish(&state, at: date("2026-11-09T10:00:00+07:00"))
        expect(state.unlockedMilestones == [3, 7])
        expect(state.longestStreak() == 7)
    }

    func purchaseUsesCatalogPriceAndCannotDoubleSpend() {
        var state = FocusState()
        let pine = Catalog.decorations.first!
        expect(!state.purchase(pine))
        finish(&state, at: date("2026-11-03T10:00:00+07:00"))
        finish(&state, at: date("2026-11-03T11:00:00+07:00"))
        expect(state.purchase(pine))
        expect(state.materials == 0)
        expect(!state.purchase(pine))
        expect(state.purchasedDecorations == ["pine"])
    }

    func persistenceRoundTripAndCorruptionIsReported() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = StateStore(fileURL: directory.appendingPathComponent("state.json"))
        try expect(try store.load() == FocusState())
        var state = FocusState()
        finish(&state, at: date("2026-11-03T10:00:00+07:00"))
        try store.save(state)
        try expect(try store.load() == state)
        try Data("invalid".utf8).write(to: store.fileURL)
        do {
            _ = try store.load()
            fatalError("Corrupt state must throw")
        } catch { /* Expected: never silently discard earned progress. */ }
    }

    func settingsCannotCreateZeroOrUnboundedTimer() {
        var state = FocusState()
        state.settings.focusMinutes = 0
        state.start()
        expect(state.activeSession?.duration == 60)
        state.endEarly()
        state.settings.focusMinutes = 1000
        state.start()
        expect(state.activeSession?.duration == 10800)
    }

    func nonGregorianCalendarStillUsesLocalCivilDay() {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        let day = FocusDay(date: date("2026-11-03T23:50:00+07:00"), calendar: buddhist)
        expect(day.key == "2026-11-03")
        expect(day.distance(to: FocusDay(date: date("2026-11-04T00:01:00+07:00"), calendar: buddhist)) == 1)
    }

    func daylightSavingDaysRemainConsecutive() {
        var eastern = Calendar(identifier: .gregorian)
        eastern.timeZone = TimeZone(identifier: "America/New_York")!
        let before = FocusDay(date: date("2026-03-07T12:00:00-05:00"), calendar: eastern)
        let after = FocusDay(date: date("2026-03-08T12:00:00-04:00"), calendar: eastern)
        expect(before.distance(to: after) == 1)
    }

#if DEBUG
    func debugIslandRewardsUseCompletionRulesAndCannotFinishActiveTimer() {
        var state = FocusState()
        let now = date("2026-11-05T10:00:00+07:00")
        state.debugGrantMaterials()
        expect(state.materials == 100)
        expect(state.totalSessions == 0)
        expect(state.completedDays.isEmpty)

        var fourthReward: CompletionReward?
        for index in 0..<4 {
            fourthReward = state.debugCompleteFocus(now: now.addingTimeInterval(Double(index) * 1800), calendar: calendar)
            expect(fourthReward?.materials == 10)
            expect(state.activeSession == nil)
        }
        expect(state.materials == 140)
        expect(state.totalSessions == 4)
        expect(state.totalFocusMinutes == 100)
        expect(state.creaturesHatched == 1)
        expect(fourthReward?.creature?.id == "fern")
        expect(state.nextKind == .longBreak)
        expect(state.currentStreak(now: now, calendar: calendar) == 1)

        state.select(.focus)
        state.start(now: now.addingTimeInterval(7200))
        let activeSnapshot = state
        expect(state.debugCompleteFocus(now: now.addingTimeInterval(7210), calendar: calendar) == nil)
        expect(state == activeSnapshot)
        state.endEarly(now: now.addingTimeInterval(7210), calendar: calendar)
        expect(state.totalSessions == 4)
        expect(state.materials == 140)
    }
#endif
}

func expect(_ condition: @autoclosure () throws -> Bool, file: StaticString = #file, line: UInt = #line) rethrows {
    if try !condition() { fatalError("Check failed", file: file, line: line) }
}

@main enum CoreChecks {
    static func main() throws {
        let suite = FocusCoreTests()
        try suite.deadlineSurvivesRelaunchAndAwardsOnlyOnce()
        print("PASS deadlineSurvivesRelaunchAndAwardsOnlyOnce")
        suite.earlyEndPreservesEarlierRewardsAndStreak()
        print("PASS earlyEndPreservesEarlierRewardsAndStreak")
        suite.endingAtDeadlineCompletesInsteadOfForfeiting()
        print("PASS endingAtDeadlineCompletesInsteadOfForfeiting")
        suite.fourthFocusHatchesCreatureAndSuggestsLongBreak()
        print("PASS fourthFocusHatchesCreatureAndSuggestsLongBreak")
        suite.midnightCreditUsesFinishDateEvenAfterLateReopen()
        print("PASS midnightCreditUsesFinishDateEvenAfterLateReopen")
        suite.multipleSessionsNeverAddExtraStreakDaysAndMissingDayResets()
        print("PASS multipleSessionsNeverAddExtraStreakDaysAndMissingDayResets")
        suite.milestonesUnlockOnceAndRemainAfterMissedDay()
        print("PASS milestonesUnlockOnceAndRemainAfterMissedDay")
        suite.purchaseUsesCatalogPriceAndCannotDoubleSpend()
        print("PASS purchaseUsesCatalogPriceAndCannotDoubleSpend")
        try suite.persistenceRoundTripAndCorruptionIsReported()
        print("PASS persistenceRoundTripAndCorruptionIsReported")
        suite.settingsCannotCreateZeroOrUnboundedTimer()
        print("PASS settingsCannotCreateZeroOrUnboundedTimer")
        suite.nonGregorianCalendarStillUsesLocalCivilDay()
        print("PASS nonGregorianCalendarStillUsesLocalCivilDay")
        suite.daylightSavingDaysRemainConsecutive()
        print("PASS daylightSavingDaysRemainConsecutive")
#if DEBUG
        suite.debugIslandRewardsUseCompletionRulesAndCannotFinishActiveTimer()
        print("PASS debugIslandRewardsUseCompletionRulesAndCannotFinishActiveTimer")
        print("13 FocusCore checks passed.")
#else
        print("12 FocusCore checks passed.")
#endif
    }
}
