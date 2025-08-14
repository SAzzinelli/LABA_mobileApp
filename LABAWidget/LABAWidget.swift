//
//  LABAWidget.swift
//  LABAWidget
//
//  Created by Simone Azzinelli on 13/08/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Theme
private enum LABATheme {
    // Brand color #033157
    static let brand = Color(red: 0.012, green: 0.192, blue: 0.341)
    static let cardCorner: CGFloat = 14
    static let cardHeight: CGFloat = 88
    static let outerPadding: CGFloat = 12
}

// MARK: - Shared Keys
private enum LABAKeys {
    static let isLoggedIn = "user.isLoggedIn"
    static let summary = "widget.summary"
    static let lastManualRefresh = "widget.lastManualRefresh"
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now,
                    configuration: ConfigurationAppIntent(),
                    displayName: "LABA Firenze",
                    passed: 0,
                    totalCFA: 0,
                    average: "N/D",
                    requiresLogin: false,
                    isNDPlaceholder: true)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if context.isPreview { // widget gallery / picker
            return SimpleEntry(date: .now,
                               configuration: configuration,
                               displayName: "LABA Firenze",
                               passed: 0,
                               totalCFA: 0,
                               average: "N/D",
                               requiresLogin: false,
                               isNDPlaceholder: true)
        }
        return readEntry(configuration: configuration) ?? placeholder(in: context)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = readEntry(configuration: configuration) ?? placeholder(in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(next))
    }

    // NOTE (App-side integration for freshness):
    // - When the app completes a sync (new avvisi/esami/CFA), write the updated LABAKeys.summary
    //   into the App Group and call:
    //     WidgetCenter.shared.reloadTimelines(ofKind: "LABAWidget")
    // - On login: set LABAKeys.isLoggedIn = true, write LABAKeys.summary, then reload timelines.
    // - On logout: set LABAKeys.isLoggedIn = false, remove LABAKeys.summary, then reload timelines.
    // This makes the widget react immediately to changes, while the timeline below provides a 30'
    // background refresh cadence as a safety net.

    // MARK: - Read shared summary from App Group
    private func readEntry(configuration: ConfigurationAppIntent) -> SimpleEntry? {
        let ud = UserDefaults(suiteName: LABA_APP_GROUP)

        // 1) Prefer data if available (avoids stale lock if app wrote the summary but not the flag yet)
        if let data = ud?.data(forKey: LABAKeys.summary),
           let s = try? JSONDecoder().decode(LABAWidgetSummary.self, from: data) {
            return SimpleEntry(date: .now,
                               configuration: configuration,
                               displayName: s.displayName,
                               passed: s.passed,
                               totalCFA: s.totalCFA,
                               average: s.average,
                               requiresLogin: false,
                               isNDPlaceholder: false)
        }

        // 2) No data -> decide between lock and N/D via login flag
        let loggedIn = ud?.bool(forKey: LABAKeys.isLoggedIn) ?? false
        if !loggedIn {
            // Not logged in -> lock
            return SimpleEntry(date: .now,
                               configuration: configuration,
                               displayName: "LABA Firenze",
                               passed: 0,
                               totalCFA: 0,
                               average: "—",
                               requiresLogin: true,
                               isNDPlaceholder: false)
        }

        // 3) Logged in but no data yet -> N/D (no lock)
        return SimpleEntry(date: .now,
                           configuration: configuration,
                           displayName: "LABA Firenze",
                           passed: 0,
                           totalCFA: 0,
                           average: "N/D",
                           requiresLogin: false,
                           isNDPlaceholder: true)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let displayName: String
    let passed: Int
    let totalCFA: Int
    let average: String
    let requiresLogin: Bool
    let isNDPlaceholder: Bool
}

// MARK: - Small stat types & view
private enum StatType {
    case exams, cfa, average
    var title: String {
        switch self {
        case .exams: return "Esami"
        case .cfa: return "CFA"
        case .average: return "Media"
        }
    }
    func value(from e: SimpleEntry) -> String {
        if e.isNDPlaceholder { return "N/D" }
        switch self {
        case .exams: return String(e.passed)
        case .cfa: return String(e.totalCFA)
        case .average: return e.average
        }
    }
}

private func iconName(for type: StatType) -> String {
    switch type {
    case .exams: return "checkmark.seal.fill"
    case .cfa: return "graduationcap.fill"
    case .average: return "chart.bar.fill"
    }
}

@ViewBuilder
private func applyWidgetBackground<Content: View>(_ content: Content) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
        content
            .containerBackground(for: .widget) { Color.clear }
            .tint(LABATheme.brand)
            .contentMargins(.all, LABATheme.outerPadding)
    } else {
        content
            .containerBackground(.background, for: .widget)
            .padding(LABATheme.outerPadding)
    }
}

private struct SmallStatEntryView: View {
    let entry: SimpleEntry
    let type: StatType
    var body: some View {
        applyWidgetBackground(
            Group {
                if entry.requiresLogin {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.secondary)
                        Text("Accedi per visualizzare i dati")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: LABATheme.cardCorner, style: .continuous)
                            .fill(.quaternary.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LABATheme.cardCorner, style: .continuous)
                            .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LABA Firenze")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: iconName(for: type))
                                    .imageScale(.small)
                                    .foregroundStyle(.secondary)
                                Text(type.title)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Text(type.value(from: entry))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .widgetAccentable()
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
        )
    }
}

struct LABAWidgetEntryView : View {
    var entry: SimpleEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        applyWidgetBackground(
            Group {
                if entry.requiresLogin {
                    switch family {
                    case .systemSmall:
                        loginSmallLayout
                    default:
                        loginMediumLayout
                    }
                } else {
                    mediumLayout
                }
            }
        )
    }

    private var smallLayout: some View {
        Link(destination: URL(string: "laba://dashboard")!) {
            VStack(alignment: .leading, spacing: 8) {
                Text("LABA Firenze")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(alignment: .center, spacing: 10) {
                    miniStat(title: "Esami", value: "\(entry.passed)")
                    Divider()
                    miniStat(title: "CFA", value: "\(entry.totalCFA)")
                    Divider()
                    miniStat(title: "Media", value: entry.average)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("LABA — Riepilogo")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
            }

            let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            LazyVGrid(columns: cols, spacing: 12) {
                Link(destination: URL(string: "laba://exams")!) {
                    statBox(title: "Esami", value: entry.isNDPlaceholder ? "N/D" : "\(entry.passed)")
                }
                Link(destination: URL(string: "laba://cfa")!) {
                    statBox(title: "CFA", value: entry.isNDPlaceholder ? "N/D" : "\(entry.totalCFA)")
                }
                Link(destination: URL(string: "laba://average")!) {
                    statBox(title: "Media", value: entry.isNDPlaceholder ? "N/D" : entry.average)
                }
            }
        }
        .padding(.top, -2)
    }




    private var loginSmallLayout: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .foregroundStyle(.secondary)
            Text("Accedi per visualizzare i dati")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LABATheme.cardCorner, style: .continuous)
                .fill(.quaternary.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LABATheme.cardCorner, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.5), lineWidth: 0.5)
        )
    }

    private var loginMediumLayout: some View {
        ZStack {
            // Bottom-anchored blurred scaffold (future content preview)
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
                LazyVGrid(columns: cols, spacing: 12) {
                    statBox(title: "Esami", value: "00")
                    statBox(title: "CFA", value: "000")
                    statBox(title: "Media", value: "00.0")
                }
                .redacted(reason: .placeholder)
                .blur(radius: 4)
                .opacity(0.8)
            }

            // Perfectly centered lock + message
            VStack(spacing: 8) {
                Image(systemName: "lock.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.secondary)
                Text("Accedi per visualizzare i dati")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.callout).bold()
                .lineLimit(1)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .widgetAccentable()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private struct StatTypeTitle: Equatable {
        let raw: String
        init(_ raw: String) { self.raw = raw }
    }
    private func iconName(for t: StatTypeTitle) -> String {
        switch t.raw.lowercased() {
        case "esami": return "checkmark.seal.fill"
        case "cfa": return "graduationcap.fill"
        case "media": return "chart.bar.fill"
        default: return "circle.fill"
        }
    }

    @ViewBuilder
    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: iconName(for: StatTypeTitle(title)))
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .widgetAccentable()
        }
        .frame(maxWidth: .infinity)
        .frame(height: LABATheme.cardHeight)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LABATheme.cardCorner, style: .continuous)
                .fill(.quaternary.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LABATheme.cardCorner, style: .continuous)
                .strokeBorder(.quaternary.opacity(0.6), lineWidth: 0.5)
        )
    }
}

struct LABAWidget: Widget {
    let kind: String = "LABAWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            // Mostra solo la versione medium estesa (3 box), mai una versione small/mini-statistica
            LABAWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LABA — Riepilogo")
        .description("Esami sostenuti, CFA totali e media.")
        .supportedFamilies([.systemMedium])
    }
}

struct LABAExamsWidgetSmall: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LABAExamsWidgetSmall", provider: SmallProvider(type: .exams)) { entry in
            SmallStatEntryView(entry: entry, type: .exams)
        }
        .configurationDisplayName("Esami sostenuti")
        .description("Totale esami superati.")
        .supportedFamilies([.systemSmall])
    }
}

struct LABACFAWidgetSmall: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LABACFAWidgetSmall", provider: SmallProvider(type: .cfa)) { entry in
            SmallStatEntryView(entry: entry, type: .cfa)
        }
        .configurationDisplayName("Crediti CFA")
        .description("Crediti formativi totali.")
        .supportedFamilies([.systemSmall])
    }
}

struct LABAMediaWidgetSmall: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LABAMediaWidgetSmall", provider: SmallProvider(type: .average)) { entry in
            SmallStatEntryView(entry: entry, type: .average)
        }
        .configurationDisplayName("Media ponderata")
        .description("Media degli esami.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - SmallProvider: per widget small senza intent/configurazione
private struct SmallProvider: TimelineProvider {
    let type: StatType

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now,
                    configuration: ConfigurationAppIntent(),
                    displayName: "LABA Firenze",
                    passed: 0,
                    totalCFA: 0,
                    average: "N/D",
                    requiresLogin: false,
                    isNDPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let entry = readEntry() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = readEntry() ?? placeholder(in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    // Copia della logica readEntry senza configuration, per rispetto isLoggedIn/requiresLogin
    private func readEntry() -> SimpleEntry? {
        let ud = UserDefaults(suiteName: LABA_APP_GROUP)

        if let data = ud?.data(forKey: LABAKeys.summary),
           let s = try? JSONDecoder().decode(LABAWidgetSummary.self, from: data) {
            return SimpleEntry(date: .now,
                               configuration: ConfigurationAppIntent(),
                               displayName: s.displayName,
                               passed: s.passed,
                               totalCFA: s.totalCFA,
                               average: s.average,
                               requiresLogin: false,
                               isNDPlaceholder: false)
        }
        let loggedIn = ud?.bool(forKey: LABAKeys.isLoggedIn) ?? false
        if !loggedIn {
            return SimpleEntry(date: .now,
                               configuration: ConfigurationAppIntent(),
                               displayName: "LABA Firenze",
                               passed: 0,
                               totalCFA: 0,
                               average: "—",
                               requiresLogin: true,
                               isNDPlaceholder: false)
        }
        return SimpleEntry(date: .now,
                           configuration: ConfigurationAppIntent(),
                           displayName: "LABA Firenze",
                           passed: 0,
                           totalCFA: 0,
                           average: "N/D",
                           requiresLogin: false,
                           isNDPlaceholder: true)
    }
}




#Preview(as: .systemSmall) {
    LABAExamsWidgetSmall()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), displayName: "LABA Firenze", passed: 12, totalCFA: 148, average: "28.7", requiresLogin: false, isNDPlaceholder: false)
}

#Preview(as: .systemSmall) {
    LABACFAWidgetSmall()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), displayName: "LABA Firenze", passed: 12, totalCFA: 148, average: "28.7", requiresLogin: false, isNDPlaceholder: false)
}

#Preview(as: .systemSmall) {
    LABAMediaWidgetSmall()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), displayName: "LABA Firenze", passed: 12, totalCFA: 148, average: "28.7", requiresLogin: false, isNDPlaceholder: false)
}

#Preview(as: .systemMedium) {
    LABAWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), displayName: "LABA Firenze", passed: 18, totalCFA: 162, average: "29.1", requiresLogin: false, isNDPlaceholder: false)
}

#Preview(as: .systemMedium) {
    LABAWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), displayName: "LABA Firenze", passed: 0, totalCFA: 0, average: "N/D", requiresLogin: false, isNDPlaceholder: true)
}

#Preview(as: .systemSmall) {
    LABAExamsWidgetSmall()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), displayName: "LABA Firenze", passed: 0, totalCFA: 0, average: "—", requiresLogin: true, isNDPlaceholder: false)
}

