import SwiftUI
import FocusCore

struct ProgressViewScreen: View {
  @EnvironmentObject private var model: AppModel
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var month = Date()

  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = .current
    calendar.timeZone = .current
    return calendar
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          VStack(alignment: .leading, spacing: 16) {
            sectionHeading("Your record")
            if dynamicTypeSize.isAccessibilitySize {
              VStack(alignment: .leading, spacing: 16) {
                currentStreakStat
                Divider()
                longestStreakStat
                Divider()
                focusTimeStat
                Divider()
                sessionsStat
              }
            } else {
              VStack(spacing: 18) {
                HStack(alignment: .top, spacing: 20) {
                  currentStreakStat
                  Divider()
                  longestStreakStat
                }.fixedSize(horizontal: false, vertical: true)
                Divider()
                HStack(alignment: .top, spacing: 20) {
                  focusTimeStat
                  Divider()
                  sessionsStat
                }.fixedSize(horizontal: false, vertical: true)
              }
            }
          }

          VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Focus calendar")
            PaperCard {
              VStack(spacing: 16) {
                HStack(spacing: 8) {
                  Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                  }.accessibilityLabel("Previous month")
                  Spacer(minLength: 0)
                  Text(monthTitle).font(.system(.subheadline, design: .monospaced).weight(.semibold)).multilineTextAlignment(.center)
                  Spacer(minLength: 0)
                  Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                  }.accessibilityLabel("Next month")
                }
                HStack(spacing: 4) {
                  ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, day in
                    Text(day).font(.system(.caption2, design: .monospaced)).foregroundStyle(IsleTheme.secondary)
                      .frame(maxWidth: .infinity).accessibilityHidden(true)
                  }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                  ForEach(0..<(leadingDays + daysInMonth), id: \.self) { offset in
                    if offset < leadingDays {
                      Color.clear.frame(height: 34).accessibilityHidden(true)
                    } else {
                      let day = offset - leadingDays + 1
                      let date = dateForDay(day)
                      let complete = model.state.completedDays.contains(FocusDay(date: date, calendar: calendar))
                      Text("\(day)")
                        .font(.system(.caption, design: .monospaced).weight(complete ? .bold : .regular))
                        .minimumScaleFactor(0.7).lineLimit(1)
                        .frame(maxWidth: .infinity).frame(minHeight: 34)
                        .background(complete ? IsleTheme.moss : .clear, in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(complete ? IsleTheme.paper : IsleTheme.ink)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(calendar.isDateInToday(date) ? IsleTheme.ink : .clear, lineWidth: 1))
                        .accessibilityLabel("\(calendarDateLabel(date)), \(complete ? "focus completed" : "no completed session")\(calendar.isDateInToday(date) ? ", today" : "")")
                    }
                  }
                }
                HStack(spacing: 8) {
                  RoundedRectangle(cornerRadius: 2).fill(IsleTheme.moss).frame(width: 10, height: 10).accessibilityHidden(true)
                  Text("Completed focus day").font(.caption).foregroundStyle(IsleTheme.secondary)
                  Spacer(minLength: 0)
                }
              }
            }
            Text("Complete one focus session to count a day. Missing a day resets your streak; earned rewards stay yours.")
              .font(.footnote).foregroundStyle(IsleTheme.secondary).fixedSize(horizontal: false, vertical: true)
          }

          VStack(alignment: .leading, spacing: 16) {
            sectionHeading("Recent sessions")
            if model.state.completedSessions.isEmpty {
              VStack(alignment: .leading, spacing: 6) {
                Text("No sessions yet").font(.subheadline.weight(.semibold))
                Text("Your completed focus sessions will appear here.").font(.footnote).foregroundStyle(IsleTheme.secondary)
              }.padding(.vertical, 8)
            } else {
              VStack(spacing: 0) {
                ForEach(Array(model.state.completedSessions.suffix(7).reversed())) { session in
                  HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(session.finishedAt.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                      Text(session.finishedAt.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(IsleTheme.secondary)
                    }
                    Spacer(minLength: 0)
                    Text("\(Int(session.duration / 60)) min").font(.system(.subheadline, design: .monospaced).weight(.semibold))
                  }.padding(.vertical, 12)
                  if session.id != model.state.completedSessions.suffix(7).first?.id { Divider() }
                }
              }
            }
          }
        }.padding(20)
      }
      .foregroundStyle(IsleTheme.ink)
      .background(IsleTheme.background)
      .navigationTitle("Progress")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("PROGRESS").font(.system(.headline, design: .monospaced)).foregroundStyle(IsleTheme.ink)
        }
      }
    }
  }

  private var currentStreakStat: some View {
    stat("Current streak", value: "\(model.state.currentStreak(now: Date(), calendar: .current))", unit: "days")
  }
  private var longestStreakStat: some View {
    stat("Longest streak", value: "\(model.state.longestStreak())", unit: "days")
  }
  private var focusTimeStat: some View {
    stat("Focus time", value: "\(model.state.totalFocusMinutes)", unit: "minutes")
  }
  private var sessionsStat: some View {
    stat("Sessions", value: "\(model.state.totalSessions)", unit: "completed")
  }
  private func stat(_ name: String, value: String, unit: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(name).font(.caption).foregroundStyle(IsleTheme.secondary)
      Text(value).font(.system(.largeTitle, design: .monospaced).weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
      Text(unit).font(.caption).foregroundStyle(IsleTheme.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
  private func sectionHeading(_ title: String) -> some View {
    Text(title.uppercased()).font(.system(.caption, design: .monospaced).weight(.bold)).foregroundStyle(IsleTheme.secondary)
  }
  private var monthTitle: String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.setLocalizedDateFormatFromTemplate("MMMM")
    return "\(formatter.string(from: month)) \(calendar.component(.year, from: month))"
  }
  private func calendarDateLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    return formatter.string(from: date)
  }
  private var weekdaySymbols: [String] {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let start = calendar.firstWeekday - 1
    return Array(symbols[start...] + symbols[..<start])
  }
  private var firstDay: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: month))! }
  private var leadingDays: Int { (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7 }
  private var daysInMonth: Int { calendar.range(of: .day, in: .month, for: month)!.count }
  private func dateForDay(_ day: Int) -> Date { calendar.date(byAdding: .day, value: day - 1, to: firstDay)! }
  private func changeMonth(_ amount: Int) { month = calendar.date(byAdding: .month, value: amount, to: firstDay)! }
}
