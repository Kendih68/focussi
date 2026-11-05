import Foundation

public enum SessionKind: String, Codable, CaseIterable, Sendable {
    case focus, shortBreak, longBreak
    public var title: String {
        switch self { case .focus: "Focus"; case .shortBreak: "Short break"; case .longBreak: "Long break" }
    }
}

public struct FocusSettings: Codable, Equatable, Sendable {
    public var focusMinutes: Int = 25
    public var shortBreakMinutes: Int = 5
    public var longBreakMinutes: Int = 15
    public init() {}
    public func minutes(for kind: SessionKind) -> Int {
        let value = switch kind {
        case .focus: focusMinutes
        case .shortBreak: shortBreakMinutes
        case .longBreak: longBreakMinutes
        }
        return min(180, max(1, value))
    }
}

public struct FocusSession: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: SessionKind
    public let startedAt: Date
    public let endsAt: Date
    public var duration: TimeInterval { endsAt.timeIntervalSince(startedAt) }
    public func remaining(at now: Date) -> TimeInterval { max(0, endsAt.timeIntervalSince(now)) }
}

/// Captured at completion so travel or a later timezone change does not move past credit.
public struct FocusDay: Codable, Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public init(date: Date, calendar: Calendar = .current) {
        // Store Gregorian dates while retaining the user's local day boundary.
        // Calendar preferences such as Buddhist years must not alter ordinal math.
        var local = Calendar(identifier: .gregorian)
        local.timeZone = calendar.timeZone
        let parts = local.dateComponents([.year, .month, .day], from: date)
        year = parts.year!; month = parts.month!; day = parts.day!
    }
    public var key: String { String(format: "%04d-%02d-%02d", year, month, day) }
    private var ordinal: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return Int(date.timeIntervalSince1970 / 86400)
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.ordinal < rhs.ordinal }
    public func distance(to other: Self) -> Int { other.ordinal - ordinal }
}

public struct SessionRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let finishedAt: Date
    public let duration: TimeInterval
    public let day: FocusDay
}

public struct Creature: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let description: String
    public let sessionsRequired: Int
}

public struct Decoration: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let cost: Int
}

public enum Catalog {
    public static let creatures: [Creature] = [
        .init(id: "fern", name: "Fern", emoji: "🐸", description: "A little friend with a big love for quiet days.", sessionsRequired: 4),
        .init(id: "clover", name: "Clover", emoji: "🐰", description: "Always finds the sunniest patch of grass.", sessionsRequired: 8),
        .init(id: "pebble", name: "Pebble", emoji: "🐢", description: "Believes good things take their time.", sessionsRequired: 12),
        .init(id: "maple", name: "Maple", emoji: "🦊", description: "Your island's curious evening explorer.", sessionsRequired: 16),
        .init(id: "mochi", name: "Mochi", emoji: "🐱", description: "An expert in the art of taking a break.", sessionsRequired: 20),
        .init(id: "pippin", name: "Pippin", emoji: "🐥", description: "Makes every morning feel like a fresh start.", sessionsRequired: 24)
    ]
    public static let decorations: [Decoration] = [
        .init(id: "pine", name: "Little pine", emoji: "🌲", cost: 20),
        .init(id: "flowers", name: "Wildflowers", emoji: "🌷", cost: 15),
        .init(id: "stones", name: "Stepping stones", emoji: "🪨", cost: 25),
        .init(id: "mushrooms", name: "Mushroom nook", emoji: "🍄", cost: 30),
        .init(id: "cottage", name: "Cozy cottage", emoji: "🏡", cost: 80),
        .init(id: "fountain", name: "Little fountain", emoji: "⛲️", cost: 60)
    ]
    public static let milestones = [3, 7, 14, 30]
}

public struct CompletionReward: Equatable, Sendable {
    public let kind: SessionKind
    public let materials: Int
    public let creature: Creature?
    public let milestones: [Int]
}

public struct FocusState: Codable, Equatable, Sendable {
    public var settings = FocusSettings()
    public private(set) var activeSession: FocusSession?
    public private(set) var nextKind: SessionKind = .focus
    public private(set) var materials = 0
    public private(set) var completedSessions: [SessionRecord] = []
    public private(set) var purchasedDecorations: [String] = []
    public private(set) var unlockedMilestones: [Int] = []
    public init() {}
    public var totalSessions: Int { completedSessions.count }
    public var totalFocusMinutes: Int { Int(completedSessions.reduce(0) { $0 + $1.duration } / 60) }
    public var creaturesHatched: Int { totalSessions / 4 }
    public var creatureProgress: Int { totalSessions % 4 }
    public var discoveredCreatures: [Creature] { Array(Catalog.creatures.prefix(min(creaturesHatched, Catalog.creatures.count))) }
    public var nextCreature: Creature { Catalog.creatures[creaturesHatched % Catalog.creatures.count] }
    public var completedDays: Set<FocusDay> { Set(completedSessions.map(\.day)) }

    public func currentStreak(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = completedDays.sorted(by: >)
        guard let last = days.first else { return 0 }
        let gap = last.distance(to: FocusDay(date: now, calendar: calendar))
        guard gap == 0 || gap == 1 else { return 0 }
        var length = 1
        for index in 1..<days.count {
            guard days[index].distance(to: days[index - 1]) == 1 else { break }
            length += 1
        }
        return length
    }

    public func longestStreak(calendar: Calendar = .current) -> Int {
        let days = completedDays.sorted()
        var best = 0, run = 0
        var previous: FocusDay?
        for day in days {
            run = previous.map { $0.distance(to: day) == 1 } == true ? run + 1 : 1
            best = max(best, run)
            previous = day
        }
        return best
    }

    /// The caller saves immediately after mutation. Starting never auto-starts a following session.
    @discardableResult public mutating func start(now: Date = Date()) -> Bool {
        guard activeSession == nil else { return false }
        activeSession = FocusSession(id: UUID(), kind: nextKind, startedAt: now,
                                     endsAt: now.addingTimeInterval(Double(settings.minutes(for: nextKind) * 60)))
        return true
    }

    /// Allows a user to skip a suggested break or choose a break before starting.
    public mutating func select(_ kind: SessionKind) {
        guard activeSession == nil else { return }
        nextKind = kind
    }

    @discardableResult public mutating func completeIfDue(now: Date = Date(), calendar: Calendar = .current) -> CompletionReward? {
        guard let session = activeSession, now >= session.endsAt else { return nil }
        activeSession = nil
        guard session.kind == .focus else {
            nextKind = .focus
            return CompletionReward(kind: session.kind, materials: 0, creature: nil, milestones: [])
        }
        // Use the deadline, not the reopen time, for day credit and recorded duration.
        completedSessions.append(SessionRecord(id: session.id, startedAt: session.startedAt,
            finishedAt: session.endsAt, duration: session.duration, day: FocusDay(date: session.endsAt, calendar: calendar)))
        materials += 10
        nextKind = totalSessions.isMultiple(of: 4) ? .longBreak : .shortBreak
        let streak = currentStreak(now: session.endsAt, calendar: calendar)
        let milestones = Catalog.milestones.filter { streak >= $0 && !unlockedMilestones.contains($0) }
        unlockedMilestones.append(contentsOf: milestones)
        let creature = totalSessions.isMultiple(of: 4) ? Catalog.creatures[(creaturesHatched - 1) % Catalog.creatures.count] : nil
        return CompletionReward(kind: .focus, materials: 10, creature: creature, milestones: milestones)
    }

    /// An elapsed session is completed even if the user taps End before the next UI tick.
    @discardableResult public mutating func endEarly(now: Date = Date(), calendar: Calendar = .current) -> CompletionReward? {
        if let reward = completeIfDue(now: now, calendar: calendar) { return reward }
        activeSession = nil
        nextKind = .focus
        return nil
    }

    @discardableResult public mutating func purchase(_ decoration: Decoration) -> Bool {
        guard let item = Catalog.decorations.first(where: { $0.id == decoration.id }),
              !purchasedDecorations.contains(item.id), materials >= item.cost else { return false }
        materials -= item.cost
        purchasedDecorations.append(item.id)
        return true
    }
}

public struct StateStore: Sendable {
    public let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }
    public func load() throws -> FocusState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return FocusState() }
        return try JSONDecoder().decode(FocusState.self, from: Data(contentsOf: fileURL))
    }
    public func save(_ state: FocusState) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state).write(to: fileURL, options: .atomic)
    }
}

#if DEBUG
extension FocusState {
    /// Development fixtures use the same completion path as a timed session.
    @discardableResult public mutating func debugCompleteFocus(now: Date = Date(), calendar: Calendar = .current) -> CompletionReward? {
        guard activeSession == nil else { return nil }
        select(.focus)
        start(now: now.addingTimeInterval(-Double(settings.minutes(for: .focus) * 60)))
        return completeIfDue(now: now, calendar: calendar)
    }

    public mutating func debugGrantMaterials() {
        materials += 100
    }
}
#endif
