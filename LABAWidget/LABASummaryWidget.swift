import WidgetKit
import SwiftUI

// Deve coincidere con l'App Group dell'app
let LABA_APP_GROUP = "group.com.labafirenze.shared"

// Copia del modello usato nell'app (rinominato per evitare conflitti di simboli)
struct LABAWidgetSummary: Codable {
    let displayName: String
    let passed: Int
    let totalCFA: Int
    let average: String
}

struct SummaryEntry: TimelineEntry {
    let date: Date
    let displayName: String
    let passed: Int
    let totalCFA: Int
    let average: String
}

struct SummaryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SummaryEntry {
        SummaryEntry(date: .now, displayName: "LABA Firenze", passed: 12, totalCFA: 148, average: "28.7")
    }
    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> ()) {
        completion(readEntry() ?? placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> ()) {
        let entry = readEntry() ?? placeholder(in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> SummaryEntry? {
        guard let ud = UserDefaults(suiteName: LABA_APP_GROUP),
              let data = ud.data(forKey: "widget.summary"),
              let s = try? JSONDecoder().decode(LABAWidgetSummary.self, from: data) else {
            return nil
        }
        return SummaryEntry(date: .now,
                            displayName: s.displayName,
                            passed: s.passed,
                            totalCFA: s.totalCFA,
                            average: s.average)
    }
}

struct LABASummaryWidgetEntryView: View {
    var entry: SummaryTimelineProvider.Entry

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Spacer()
                    Text("LABA Firenze")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    row("Esami sostenuti", value: "\(entry.passed)")
                    row("CFA totali", value: "\(entry.totalCFA)")
                    row("Media", value: entry.average)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.footnote).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.callout).bold()
        }
    }
}

struct LABASummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LABASummaryWidget", provider: SummaryTimelineProvider()) { entry in
            LABASummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LABA — Riepilogo")
        .description("Esami sostenuti, CFA totali e media ponderata.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
