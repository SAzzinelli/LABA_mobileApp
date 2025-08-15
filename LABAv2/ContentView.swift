import CoreHaptics
// MARK: - ConfettiView (Easter Egg)
struct LABAEggView: View {
    var onClose: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            // Confetti layer personalizzato
            ConfettiLayer(confettiColor: scheme == .dark ? .white : UIColor(Color.labaAccent))
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Spacer(minLength: 40)
                Text("🎉 VIVALABA! 🎉")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(scheme == .dark ? .white : .black)

                Text("""
                Complimenti, sei entrato in una realtà meravigliosa,
                quella della nostra accademia.

                Sei un grande esploratore,
                sei un meraviglioso utente.
                """)
                .multilineTextAlignment(.center)
                .font(.title3)
                .foregroundStyle(scheme == .dark ? .white.opacity(0.95) : .black.opacity(0.95))
                .padding(.horizontal, 24)

                Spacer()

                Button(action: onClose) {
                    Text("Chiudi")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(scheme == .dark ? Color.white : Color.labaAccent)
                        )
                        .foregroundColor(scheme == .dark ? .black : .white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct ConfettiLayer: UIViewRepresentable {
    var confettiColor: UIColor

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: -10)
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)

        var cells: [CAEmitterCell] = []
        let symbols = ["circle.fill", "square.fill", "triangle.fill", "seal.fill"]
        for sym in symbols {
            let c = CAEmitterCell()
            c.contents = UIImage(systemName: sym)?
                .withTintColor(confettiColor, renderingMode: .alwaysOriginal).cgImage
            c.birthRate = 6
            c.lifetime = 10
            c.velocity = 160
            c.velocityRange = 60
            c.scale = 0.06
            c.scaleRange = 0.03
            c.emissionLongitude = .pi
            c.emissionRange = .pi / 4
            c.spin = 2
            c.spinRange = 2
            cells.append(c)
        }
        emitter.emitterCells = cells
        v.layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            emitter.birthRate = 0
        }
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
//
//  ContentView.swift
//  LABAv2
//
//  Full app with real API integration + PKCE/SSO fallback when password grant is not allowed.
//

import SwiftUI
import Foundation
import Combine
import PhotosUI
import UIKit
import UserNotifications

// MARK: - AppDelegate per catturare il token APNs
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📲 Device Token: \(token)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Registrazione notifiche fallita: \(error.localizedDescription)")
    }
}

#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Color and Styling Constants

extension Color {
    static let labaPrimary = Color(red: 3/255, green: 49/255, blue: 87/255) // #033157 HEX
    static let cardBG = Color(.secondarySystemBackground)
    static let pillBGYear = Color(.systemBlue)
    static let pillBGGrade = Color(.systemGreen)
    static let pillBGCFA = Color(.systemOrange)
    static let pillBGStatus = Color(.systemOrange)
    static let pillBGYear1 = Color(.systemBlue)
    static let pillBGYear2 = Color(.systemTeal)
    static let pillBGYear3 = Color(.systemIndigo)
    static let pillBGLaureato = Color(.systemOrange)
}

// Pre-warm commonly used SF Symbols so the tab bar icons don't lag on first render
@inline(__always)
func warmUpSymbols() {
    #if canImport(UIKit)
    let names = [
        "house", "graduationcap", "bell", "person.crop.circle",
        // add any other symbols you use often in headers or toolbars
        "calendar", "ellipsis.circle", "info.circle", "lock.fill", "person.fill"
    ]
    let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
    for n in names {
        _ = UIImage(systemName: n, withConfiguration: config)
    }
    #endif
}

// MARK: - Helper Functions

func ddMMyyyy(_ date: Date?) -> String {
    guard let date else { return "-" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "dd/MM/yyyy"
    return f.string(from: date)
}

func parseAPIDate(_ s: String?) -> Date? {
    guard let s = s, !s.isEmpty else { return nil }
    let f1 = DateFormatter(); f1.locale = Locale(identifier: "en_US_POSIX"); f1.timeZone = .init(secondsFromGMT: 0); f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    let f2 = DateFormatter(); f2.locale = Locale(identifier: "en_US_POSIX"); f2.timeZone = .init(secondsFromGMT: 0); f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return f1.date(from: s) ?? f2.date(from: s)
}

func italianOrdinalYear(_ y: Int) -> String {
    switch y { case 1: return "1° anno"; case 2: return "2° anno"; case 3: return "3° anno"; default: return "\(y)° anno" }
}

func preferredScheme(from pref: String) -> ColorScheme? {
    switch pref {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
}

func normalizeNameForEmail(_ s: String) -> String {
    let lowered = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let replaced = lowered.replacingOccurrences(of: " ", with: ".")
    return replaced
}

func fullName(from base: String) -> String {
    let parts = base.split(separator: ".").map { String($0) }
    guard !parts.isEmpty else { return base.capitalized }
    let cap = parts.map { $0.replacingOccurrences(of: "-", with: " ").capitalized }
    return cap.joined(separator: " ")
}

func prettifyTitle(_ s: String) -> String {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }

    // If it arrives ALL CAPS, bring it down before capitalizing
    let base = (trimmed == trimmed.uppercased()) ? trimmed.lowercased() : trimmed

    // Title-case first, then fix prepositions/conjunctions
    let titled = base.capitalized(with: Locale(identifier: "it_IT"))

    let lowerWords: Set<String> = [
        "di","a","da","in","con","su","per","tra","fra","e","o",
        "del","dello","della","dei","degli","delle","dell'",
        "al","allo","alla","ai","agli","alle","all'",
        "nel","nello","nella","nei","negli","nelle","nell'",
        "sul","sullo","sulla","sui","sugli","sulle","sull'"
    ]

    var out: [String] = []
    let tokens = titled.split(separator: " ")
    for (i, raw) in tokens.enumerated() {
        var tok = String(raw)
        let lower = tok.lowercased()
        if i > 0, lowerWords.contains(lower) {
            tok = lower
        }
        out.append(tok)
    }
    return out.joined(separator: " ")
}

// Dynamic accent color
struct AccentPalette {
    static func color(named: String) -> Color {
        switch named {
        case "system":   return Color.accentColor      // usata a runtime
        case "brand":    return Color.labaPrimary
        case "peach":    return Color(red: 0.99, green: 0.58, blue: 0.47)
        case "lavender": return Color(red: 0.57, green: 0.53, blue: 0.96)
        case "mint":     return Color(red: 0.36, green: 0.78, blue: 0.66)
        case "sand":     return Color(red: 0.86, green: 0.75, blue: 0.58)
        case "sky":      return Color(red: 0.35, green: 0.68, blue: 0.93)
        default:         return Color.accentColor
        }
    }

    // anteprima statica per la UI (il dot della lista)
    static func previewColor(named: String) -> Color {
        switch named {
        case "system":
            return Color(uiColor: .systemBlue) // blu iOS fisso
        default:
            return color(named: named)
        }
    }
}

func labaTint(_ scheme: ColorScheme) -> Color {
    // Dark mode: B/N come richiesto
    if scheme == .dark { return .white }
    // Light mode: usa accento scelto (default sistema)
    let choice = UserDefaults.standard.string(forKey: "laba.accent") ?? "system"
    if choice == "system" { return .accentColor }
    return AccentPalette.color(named: choice)
}
func yearTint(_ year: Int?) -> Color? {
    guard let year = year else { return nil }
    switch year {
    case 1: return Color.pillBGYear1
    case 2: return Color.pillBGYear2
    case 3: return Color.pillBGYear3
    default: return Color.pillBGYear
    }
}

func teacherEmails(from docente: String) -> [String] {
    let parts = docente.split(separator: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    return parts.compactMap { full in
        let comps = full.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard comps.count >= 2 else { return nil }
        let first = comps[0]
        let last = comps.dropFirst().joined() // unisce cognomi composti: Dalla Valle -> DallaValle; Di Lella -> DiLella
        var base = "\(first).\(last)"
        base = base.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        return base + "@labafirenze.com"
    }
}

func courseDisplayInfo(from piano: String?) -> (name: String, aa: String)? {
    guard let p = piano, !p.isEmpty else { return nil }
    let upper = p.uppercased()
    let parts = upper.components(separatedBy: "A.A.")
    let courseRaw = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? upper
    let yearsRaw = parts.count > 1 ? parts[1] : ""

    // Preferisci match più specifici prima dei generici
    let patterns: [(key: String, value: String)] = [
        ("GRAPHIC DESIGN & MULTIMEDIA", "Graphic Design"),
        ("PITTURA", "Pittura"),
        ("FASHION DESIGN", "Fashion Design"),
        ("REGIA E VIDEOMAKING", "Regia e Videomaking"),
        ("INTERIOR DESIGN", "Interior Design"),
        ("CINEMA E AUDIOVISIVI", "Cinema e Audiovisivi"),
        ("FOTOGRAFIA", "Fotografia"),
        ("DESIGN", "Design") // generico in fondo
    ]

    var name = courseRaw
    for (k, v) in patterns { if courseRaw.contains(k) { name = v; break } }

    let digits = yearsRaw.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
    var aa = ""
    if digits.count >= 2, let s = digits.first, let e = digits.dropFirst().first {
        let s2 = String(s.suffix(2))
        let e2 = String(e.suffix(2))
        aa = "A.A. \(s2)/\(e2)"
    }
    return (name, aa)
}

// HTML → plain text helper
func plainText(from html: String?) -> String {
    guard let html, let data = html.data(using: .utf8) else { return html ?? "" }
    if let att = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
        return att.string
    }
    return html
}

// MARK: - Seminari Helpers

struct SeminarDetails {
    var docente: String?
    var dateLines: [String] = []
    var aula: String?
    var allievi: String?
    var cfa: String?
    var assenze: String?
    var completed: Bool = false
    var groups: [(label: String, time: String)] = []
}

/// Rimuove tutto ciò che è tra parentesi tonde (anche annidate)
func stripParentheses(_ s: String) -> String {
    var out = ""
    var depth = 0
    for ch in s {
        if ch == "(" { depth += 1; continue }
        if ch == ")" { if depth > 0 { depth -= 1 }; continue }
        if depth == 0 { out.append(ch) }
    }
    return out.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Restituisce SOLO il testo tra virgolette ( “ … ” oppure " ... " ).
/// Rimuove anche prefissi come SEMINARIO/WORKSHOP e i suffissi tra parentesi.
func seminarTitle(from s: String) -> String {
    let noParens = stripParentheses(s)
    if let o = noParens.firstIndex(of: "“"),
       let c = noParens[noParens.index(after: o)...].firstIndex(of: "”") {
        return String(noParens[noParens.index(after: o)..<c]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let o = noParens.firstIndex(of: "\""),
       let c = noParens[noParens.index(after: o)...].firstIndex(of: "\"") {
        return String(noParens[noParens.index(after: o)..<c]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let prefixes = ["SEMINARIO", "WORKSHOP"]
    var t = noParens.trimmingCharacters(in: .whitespaces)
    for p in prefixes where t.uppercased().hasPrefix(p) {
        t = t.dropFirst(p.count).trimmingCharacters(in: .whitespacesAndNewlines)
        break
    }
    return t
}

func parseSeminarDetails(html: String?, esito: String?) -> SeminarDetails {
    var d = SeminarDetails()
    let text = plainText(from: html).replacingOccurrences(of: "\u{00a0}", with: " ")
    let lines = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    func extract(after key: String) -> String? {
        if let line = lines.first(where: { $0.lowercased().hasPrefix(key.lowercased()) }) {
            return line.dropFirst(key.count).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    if let rawDoc = extract(after: "Docente:") ?? extract(after: "Docenti:") {
        d.docente = cleanTeacherList(rawDoc)
    }

    // Date (solo righe con mesi). Evita orario/gruppi qui.
    if let idx = lines.firstIndex(where: { $0.lowercased().hasPrefix("date:") || $0.lowercased().hasPrefix("orario") }) {
        var collected: [String] = []
        for i in idx..<min(lines.count, idx+12) {
            let raw = lines[i]
            let l = raw
                .replacingOccurrences(of: "Date:", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Orario:", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
            let lower = l.lowercased()
            if lower.hasPrefix("allievi") || lower.hasPrefix("aula") || lower.contains("cfa") { break }

            if lower.contains("gruppo") {
                // Estrai gruppi/orari (safe regex)
                if let timeRx = try? NSRegularExpression(
                    pattern: #"\b\d{1,2}[:.]\d{2}\b(\s?[–\u{2013}\u{2014}-]\s?\d{1,2}[:.]\d{2}\b)?"#,
                    options: []
                ) {
                    let ns = l as NSString
                    let time = timeRx.firstMatch(in: l, range: NSRange(location: 0, length: ns.length)).map { ns.substring(with: $0.range) } ?? ""
                    if let gr = l.range(of: #"(?i)gruppo\s*([A-Za-z0-9]+)"#, options: .regularExpression) {
                        let label = l[gr].replacingOccurrences(of: "gruppo", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                        d.groups.append((label: label.uppercased(), time: time))
                    }
                }
                continue
            }

            if containsMonthName(l) { collected.append(l) }
        }
        d.dateLines = formatSeminarDateLines(collected)
    }

    d.aula = extract(after: "Aula:") ?? extract(after: "Aula :")
    d.allievi = extract(after: "Allievi:") ?? extract(after: "Allievi :")

    // Estrai SOLO i crediti (CFA) senza riportare frasi sulle assenze
    if let cfaLine = lines.first(where: { $0.range(of: "CFA", options: .caseInsensitive) != nil }) {
        // prova a catturare un numero di crediti (1 o 2 cifre)
        if let rx = try? NSRegularExpression(pattern: "(?i)(?:N°\\s*)?(\\n?\\r?\\s*)?(\\d{1,2})\\s*CFA|CFA\\s*(\\d{1,2})", options: [] ) {
            let ns = cfaLine as NSString
            let r = NSRange(location: 0, length: ns.length)
            if let m = rx.firstMatch(in: cfaLine, options: [], range: r) {
                // gruppo 2 o 3 contiene il numero
                let g2 = m.range(at: 2)
                let g3 = m.range(at: 3)
                var number: String? = nil
                if g2.location != NSNotFound { number = ns.substring(with: g2) }
                else if g3.location != NSNotFound { number = ns.substring(with: g3) }
                if let number { d.cfa = number }
            }
        }
        if d.cfa == nil {
            // fallback morbido: ripulisci la frase dai prefissi noti
            d.cfa = cfaLine
                .replacingOccurrences(of: "Il Seminario consente l’acquisizione di", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Il Seminario prevede l’acquisizione di", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "crediti formativi", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "N°", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespaces)
        }
    }

    if let line = lines.first(where: { $0.range(of: "assenz", options: .caseInsensitive) != nil }) {
        d.assenze = extractAssenzaSentence(line)
    }

    if let e = esito?.lowercased(), e.contains("complet") || e.contains("approv") || e.contains("valid") {
        d.completed = true
    }
    return d
}

/// Converte la stringa di “Allievi” in coppie (anno, corso) per mostrare pillole.
func allieviGroups(from s: String?) -> [(anno: Int?, corso: String?)] {
    guard let s = s, !s.isEmpty else { return [] }
    let parts = s.components(separatedBy: CharacterSet(charactersIn: "+,;"))
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    var out: [(Int?, String?)] = []
    for p in parts {
        var year: Int? = nil
        if let r = p.range(of: #"(\d)°"#, options: .regularExpression) {
            let yStr = p[r].replacingOccurrences(of: "°", with: "")
            year = Int(yStr)
        }
        let hints: [(String,String)] = [
            ("GD","Graphic Design & Multimedia"),
            ("Graphic Design","Graphic Design & Multimedia"),
            ("Design","Design"),
            ("Fotografia","Fotografia"),
            ("Fashion","Fashion Design"),
            ("Pittura","Pittura"),
            ("Regia","Regia e Videomaking"),
            ("Cinema","Cinema e Audiovisivi"),
            ("Interior","Interior Design")
        ]
        var course: String? = nil
        for (k,v) in hints where p.range(of: k, options: .caseInsensitive) != nil { course = v; break }
        out.append((year, course))
    }
    return out
}

// MARK: - Seminari formatting helpers

private let itMonths: [String] = ["gennaio","febbraio","marzo","aprile","maggio","giugno","luglio","agosto","settembre","ottobre","novembre","dicembre"]

func containsMonthName(_ s: String) -> Bool {
    let l = s.lowercased()
    return itMonths.contains { l.contains($0) }
}

func capMonth(_ m: String) -> String {
    guard let f = m.first else { return m }
    return String(f).uppercased() + m.dropFirst().lowercased()
}

/// Concatena e riformatta le linee data in blocchi per mese:
/// es. "Sabato 15 Febbraio", "22 Marzo", "5 e 12 Aprile"
func formatSeminarDateLines(_ lines: [String]) -> [String] {
    var s = lines.joined(separator: " ")
    s = s.replacingOccurrences(of: "  ", with: " ")
    // rimuovi indicazioni orarie generiche
    s = s.replacingOccurrences(of: " ore ", with: " ", options: .caseInsensitive)
    if let timeRegex = try? NSRegularExpression(
        pattern: #"\b\d{1,2}[:.]\d{2}\b(\s?[–\u{2013}\u{2014}-]\s?\d{1,2}[:.]\d{2}\b)?"#,
        options: []
    ) {
        s = timeRegex.stringByReplacingMatches(in: s, options: [], range: NSRange(location: 0, length: s.utf16.count), withTemplate: "")
    }
    s = s.replacingOccurrences(of: "  ", with: " ")

    let monthsPattern = itMonths.joined(separator: "|")
    guard let regex = try? NSRegularExpression(
        pattern: "(?i)([\\p{L}\\s]*?\\d{1,2}(?:\\s*e\\s*\\d{1,2})?)\\s+(" + monthsPattern + ")",
        options: []
    ) else {
        return lines
    }
    let ns = s as NSString
    let matches = regex.matches(in: s, range: NSRange(location: 0, length: ns.length))
    var out: [String] = []
    for m in matches {
        guard m.numberOfRanges >= 3 else { continue }
        var left = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
        left = left.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "–", with: " ")
        let month = ns.substring(with: m.range(at: 2)).lowercased()
        if left.isEmpty { continue }
        out.append("\(left.capitalized) \(capMonth(month))")
    }
    return out.isEmpty ? lines : out
}

/// Pulisce prefissi come Prof./Prof.ssa/Avv./Dott. dai nomi docenti.
/// Supporta liste separate da "/".
func cleanTeacherList(_ raw: String) -> String {
    let parts = raw.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
    let rx = try? NSRegularExpression(pattern: #"(?i)^(prof\.?\s*(ssa|ss|sso)?|avv\.?|dott\.?|dr\.?|ing\.?|arch\.?|maestro|maestra)\s+"#, options: [])
    func cleanOne(_ s: String) -> String {
        let ns = s as NSString
        let r = NSRange(location: 0, length: ns.length)
        let cleaned: String
        if let rx {
            cleaned = rx.stringByReplacingMatches(in: s, options: [], range: r, withTemplate: "")
        } else {
            cleaned = s
        }
        return prettifyTitle(cleaned.trimmingCharacters(in: .whitespaces))
    }
    return parts.map(cleanOne).joined(separator: " / ")
}

/// Estrae solo la frase che parla di assenze, senza pezzi sui crediti.
func extractAssenzaSentence(_ s: String) -> String {
    if let r = s.range(of: #"(?i)[^.]*assenz[^.]*"#, options: .regularExpression) {
        return String(s[r]).trimmingCharacters(in: .whitespaces)
    }
    return s
}

// MARK: - Remote Models

struct EnrollmentsResponse: Decodable {
    let success: Bool
    let payload: EnrollmentsPayload?
    let errorSummary: String?
}

struct EnrollmentsPayload: Decodable {
    let stato: String?
    let dataStato: String?
    let annoAttuale: Int?
    let pianoStudi: String?
    let situazioneEsami: [RemoteExam]
}

struct StudentResponse: Decodable {
    let success: Bool
    let payload: StudentPayload?
    let errorSummary: String?
}

struct StudentPayload: Decodable {
    let nome: String?
    let cognome: String?
    let numMatricola: String?
    let emailPersonale: String?
    let emailLABA: String?
    let telefono: String?
    let cellulare: String?
    let codiceFiscale: String?
    let sesso: String?
    let pagamenti: String?
    let oid: String?          // 👈 aggiunto
}

struct RemoteExam: Decodable {
    let oidCorso: String
    let ordine: Int?
    let corso: String
    let docente: String?
    let anno: Int?
    let cfa: String?
    let propedeutico: String?
    let sostenutoIl: String?
    let voto: String?
    let ssd: String?
    let dataRichiesta: String?
    let esitoRichiesta: String?
    let richiedibile: String?
}

// Seminars remote models
struct SeminariResponse: Decodable {
    let success: Bool
    let payload: [SeminarioPayload]?
    let errorSummary: String?
}
struct SeminarioPayload: Decodable {
    let seminarioOid: String
    let descrizione: String
    let descrizioneEstesa: String?
    let documentOid: String?
    let dataRichiesta: String?
    let esitoRichiesta: String?
    let richiedibile: String?
}

// Notifications remote models
struct NotificationsResponse: Decodable {
    let success: Bool
    let payload: [NotificationPayload]?
    let errorSummary: String?
}

struct NotificationsAnyWrapper: Decodable {
    let data: [NotificationPayload]?
    let payload: [NotificationPayload]?
}

struct NotificationPayload: Decodable {
    let id: Int
    let dataOraCreazione: String?
    let tipo: String?
    let oggetto: String?
    let messaggio: String
    let parametro: String?
    let allievoOId: String?
    let dataOraLetturaNotifica: String?
    let playerId: String?
}

// App model for notifications
struct NotificationItem: Identifiable, Hashable {
    let id: Int
    var title: String?
    var message: String
    var createdAt: Date?
    var readAt: Date?

    var isRead: Bool { readAt != nil }
}

fileprivate func itDateTime(_ d: Date?) -> String {
    guard let d else { return "—" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "it_IT")
    f.dateFormat = "dd/MM/yyyy HH:mm"
    return f.string(from: d)
}

// MARK: - App Models

struct Esame: Identifiable {
    let id: String
    let corso: String
    let docente: String?
    let anno: Int?
    let cfa: String?
    let propedeutico: String?
    let sostenutoIl: Date?
    let voto: String?
    let richiedibile: Bool
}

struct Seminario: Identifiable {
    let id: String
    let titolo: String
    let descrizioneEstesa: String?
    let richiedibile: Bool
    let esito: String?
}

// MARK: - API Client (IdentityServer + PKCE)

final class APIClient {
    static let shared = APIClient()

    // NOTE: You might need a dedicated **mobile** client_id from IdentityServer.
    // The SPA client often doesn't allow password grant. If you *do* have a secret, set it here.
    var clientId: String = "98C96373243D" // from earlier token claims
    var clientSecret: String? = "B1355BBB-EA35-4724-AFAA-8ABAAFEDCFB6"       // from HAR (confidential client)

    let issuerBase = URL(string: "https://logosuni.laba.biz/identityserver")!
    // Scopes separated per flow: the HAR showed only LogosUni.Laba.Api for password grant
    let scopeROPC = "LogosUni.Laba.Api"

    private var tokenURL: URL { issuerBase.appendingPathComponent("connect/token") }
    private let enrollmentsURL = URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Enrollments")!
    private let studentURL = URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Students")!
    private let seminarsURL = URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Seminars")!
    private let notificationsURLv1 = URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notifications")!
    private let notificationsURLv2 = URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notification/GetNotifications")!
    private let notificationMarkReadURL = URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notification/MarkAsRead")!

    private func buildNotificationURLs(studentOid: String?) -> [URL] {
        var urls: [URL] = []
        // v2 base
        urls.append(URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notification/GetNotifications")!)
        // v2 with paging
        if var c = URLComponents(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notification/GetNotifications") {
            c.queryItems = [URLQueryItem(name: "start", value: "0"),
                            URLQueryItem(name: "count", value: "100")]
            if let u = c.url { urls.append(u) }
        }
        // v2 with possible student filter (name variant 1)
        if let oid = studentOid, var c = URLComponents(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notification/GetNotifications") {
            c.queryItems = [URLQueryItem(name: "allievoOid", value: oid),
                            URLQueryItem(name: "start", value: "0"),
                            URLQueryItem(name: "count", value: "100")]
            if let u = c.url { urls.append(u) }
        }
        // v2 with possible student filter (name variant 2 - as in payload key)
        if let oid = studentOid, var c = URLComponents(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notification/GetNotifications") {
            c.queryItems = [URLQueryItem(name: "allievoOId", value: oid)]
            if let u = c.url { urls.append(u) }
        }
        // legacy plural
        urls.append(URL(string: "https://logosuni.laba.biz/logosuni.servicesv2/api/Notifications")!)
        return urls
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    struct TokenResponse: Decodable { let access_token: String; let refresh_token: String?; let expires_in: Int }

    // ROPC (legacy). Will fail with invalid_client if the client doesn't allow it.
    func loginROPC(email: String, password: String) async throws -> TokenResponse {
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        var pairs = [
            ("client_id", clientId),
            ("grant_type", "password"),
            ("username", email),
            ("password", password),
            ("scope", scopeROPC)
        ]
        if let secret = clientSecret { pairs.append(("client_secret", secret)) }
        let body = pairs.map { "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Login failed: \(txt)"])
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    // MARK: API
    func enrollments(token: String) async throws -> EnrollmentsPayload {
        var req = URLRequest(url: enrollmentsURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Enrollments failed: \(txt)"])
        }
        let dec = JSONDecoder()
        let root = try dec.decode(EnrollmentsResponse.self, from: data)
        guard root.success, let payload = root.payload else {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: root.errorSummary ?? "Unknown error"])
        }
        return payload
    }

    func student(token: String) async throws -> StudentPayload {
        var req = URLRequest(url: studentURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Student failed: \(txt)"])
        }
        let dec = JSONDecoder()
        let root = try dec.decode(StudentResponse.self, from: data)
        guard root.success, let payload = root.payload else {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: root.errorSummary ?? "Unknown error"])
        }
        return payload
    }

    func seminars(token: String) async throws -> [SeminarioPayload] {
        var req = URLRequest(url: seminarsURL)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Seminars failed: \(txt)"])
        }
        let dec = JSONDecoder()
        let root = try dec.decode(SeminariResponse.self, from: data)
        guard root.success, let payload = root.payload else {
            throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: root.errorSummary ?? "Unknown error"]) }
        return payload
    }



    func notifications(token: String, studentOid: String?) async throws -> [NotificationPayload] {
        // Prefer POST first (405 on GET observed in prod), then try GET fallbacks
        if let posted = try? await postNotifications(token: token, studentOid: studentOid) {
            return posted
        }

        let endpoints = buildNotificationURLs(studentOid: studentOid)
        var lastError: Error? = nil
        for url in endpoints {
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            do {
                let (data, resp) = try await session.data(for: req)
                guard let http = resp as? HTTPURLResponse else {
                    throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Notifications: invalid response"])
                }
                print("Notifications GET: \(url.absoluteString) → status \(http.statusCode)")
                if http.statusCode == 405 { // Method not allowed → prefer POST
                    lastError = NSError(domain: "API", code: 405, userInfo: [NSLocalizedDescriptionKey: "Notifications GET not allowed at \(url.path)"])
                    continue
                }
                guard (200..<300).contains(http.statusCode) else {
                    if http.statusCode == 404 || http.statusCode == 401 || http.statusCode == 403 {
                        lastError = NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Notifications failed \(http.statusCode) at \(url.path)"])
                        continue
                    }
                    let txt = String(data: data, encoding: .utf8) ?? "<no body>"
                    throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Notifications failed: \(txt)"])
                }

                if let arr = decodeNotifications(data) { return arr }
                lastError = NSError(domain: "API", code: -2, userInfo: [NSLocalizedDescriptionKey: "Notifications: unexpected shape at \(url.path)"])
            } catch {
                print("Notifications GET error at \(url.absoluteString): \(error)")
                lastError = error
            }
        }

        // Final POST attempt if not yet tried successfully
        if let posted = try? await postNotifications(token: token, studentOid: studentOid) {
            return posted
        }
        throw lastError ?? NSError(domain: "API", code: -3, userInfo: [NSLocalizedDescriptionKey: "Notifications: all endpoints failed"])
    }

    private func decodeNotifications(_ data: Data) -> [NotificationPayload]? {
        let dec = JSONDecoder()
        if let wrapped = try? dec.decode(NotificationsResponse.self, from: data),
           (wrapped.success || wrapped.payload != nil), let payload = wrapped.payload { return payload }
        if let alt = try? dec.decode(NotificationsAnyWrapper.self, from: data),
           let arr = alt.data ?? alt.payload { return arr }
        if let arr = try? dec.decode([NotificationPayload].self, from: data) { return arr }
        return nil
    }

    private func postNotifications(token: String, studentOid: String?) async throws -> [NotificationPayload] {
        // Attempt 1: POST with JSON body
        do {
            var req = URLRequest(url: notificationsURLv2)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            var body: [String: Any] = ["start": 0, "count": 100]
            if let oid = studentOid, !oid.isEmpty { body["allievoOId"] = oid }
            req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Notifications POST: invalid response"])
            }
            print("Notifications POST: \(notificationsURLv2.absoluteString) → status \(http.statusCode)")
            guard (200..<300).contains(http.statusCode) else {
                if http.statusCode == 204 { return [] }
                let txt = String(data: data, encoding: .utf8) ?? "<no body>"
                throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Notifications POST failed: \(txt)"])
            }
            if let arr = decodeNotifications(data) { return arr }
        } catch {
            print("Notifications POST error (JSON body): \(error)")
        }

        // Attempt 2: POST with query items instead of body (some backends read only query)
        if var comps = URLComponents(url: notificationsURLv2, resolvingAgainstBaseURL: false) {
            var items = [URLQueryItem(name: "start", value: "0"), URLQueryItem(name: "count", value: "100")]
            if let oid = studentOid, !oid.isEmpty { items.append(URLQueryItem(name: "allievoOId", value: oid)) }
            comps.queryItems = items
            if let urlQ = comps.url {
                do {
                    var req = URLRequest(url: urlQ)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Accept")
                    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    let (data, resp) = try await session.data(for: req)
                    guard let http = resp as? HTTPURLResponse else {
                        throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Notifications POST(query): invalid response"])
                    }
                    print("Notifications POST(query): \(urlQ.absoluteString) → status \(http.statusCode)")
                    guard (200..<300).contains(http.statusCode) else {
                        if http.statusCode == 204 { return [] }
                        let txt = String(data: data, encoding: .utf8) ?? "<no body>"
                        throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Notifications POST(query) failed: \(txt)"])
                    }
                    if let arr = decodeNotifications(data) { return arr }
                } catch {
                    print("Notifications POST(query) error: \(error)")
                }
            }
        }
        throw NSError(domain: "API", code: -4, userInfo: [NSLocalizedDescriptionKey: "Notifications POST attempts failed"])
    }

    /// Best-effort: try to mark a notification as read in backend if supported. Fails silently.
    func markNotificationRead(token: String, id: Int) async {
        // Preferred: POST JSON { id: ... }
        do {
            var r = URLRequest(url: notificationMarkReadURL)
            r.httpMethod = "POST"
            r.setValue("application/json", forHTTPHeaderField: "Accept")
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = ["id": id]
            r.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            _ = try await session.data(for: r)
            return
        } catch {
            print("MarkAsRead JSON body failed: \(error)")
        }
        // Fallback legacy: POST with query
        if let url1 = URL(string: notificationsURLv1.absoluteString + "/Read?id=\(id)") {
            var r = URLRequest(url: url1)
            r.httpMethod = "POST"
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await session.data(for: r)
        }
    }
}


// MARK: - Session ViewModel

// App Group usato per condividere dati col widget.

let LABA_APP_GROUP = "group.com.labafirenze.shared"  // MUST match the App Group ID in Signing & Capabilities (App + Widget)

#if canImport(UIKit)
fileprivate enum Device {
    static var isMini: Bool {
        // iPhone 12/13 mini have native long side = 2340px. Treat <= 2340 as "mini".
        let h = max(UIScreen.main.nativeBounds.width, UIScreen.main.nativeBounds.height)
        return h <= 2340
    }
}
#endif

fileprivate let labaDomain = "@labafirenze.com"

struct WidgetSummary: Codable {
    let displayName: String
    let passed: Int
    let totalCFA: Int
    let average: String
}

final class SessionVM: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var displayName: String? = nil
    @Published var status: String? = nil
    @Published var currentYear: Int? = nil
    @Published var esami: [Esame] = []
    @Published var loading: Bool = false
    @Published var error: String? = nil
    @Published var pianoStudi: String? = nil
    @Published var nome: String? = nil
    @Published var cognome: String? = nil
    @Published var matricola: String? = nil
    @Published var sesso: String? = nil
    @Published var emailLABA: String? = nil
    @Published var emailPersonale: String? = nil
    @Published var telefono: String? = nil
    @Published var cellulare: String? = nil
    @Published var pagamenti: String? = nil
    @Published var studentOid: String? = nil
    @Published var seminari: [Seminario] = []
    @Published var notifications: [NotificationItem] = []

    // Local read state cache so the badge works even if the backend doesn't persist read state for mobile yet
    @AppStorage("laba.readNotificationIDs") private var readIDsData: Data = Data()
    private var localReadIDs: Set<Int> {
        get { (try? JSONDecoder().decode(Set<Int>.self, from: readIDsData)) ?? [] }
        set { readIDsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var unreadNotificationsCount: Int {
        notifications.filter { !$0.isRead && !localReadIDs.contains($0.id) }.count
    }

    // Badges
    var bookableExamsCount: Int { esami.filter { $0.richiedibile }.count }
    var bookableSeminarsCount: Int { seminari.filter { $0.richiedibile }.count }

    @AppStorage("laba.accessToken") var accessToken: String = ""
    @AppStorage("laba.usernameBase") private var usernameBase: String = ""
    
    /// Sync login state to the Widget (App Group) and refresh timelines.
    private func setWidgetLoginState(_ loggedIn: Bool) {
        if let ud = UserDefaults(suiteName: LABA_APP_GROUP) {
            ud.set(loggedIn, forKey: "user.isLoggedIn")
            ud.synchronize()
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "LABAWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "LABAExamsWidgetSmall")
        WidgetCenter.shared.reloadTimelines(ofKind: "LABACFAWidgetSmall")
        WidgetCenter.shared.reloadTimelines(ofKind: "LABAMediaWidgetSmall")
        #endif
    }

    private func updateWidgetSummary() {
        let passed = esami.filter { !($0.voto ?? "").isEmpty }.count
        let totalCFA = esami.compactMap { Int($0.cfa ?? "") }.reduce(0, +)

        // media matematica (esclude Tesi/Attività a scelta e “idoneo”)
        let valid = esami.filter { e in
            let nameUp = e.corso.uppercased()
            let isOther = nameUp.contains("ATTIVITA' A SCELTA") || nameUp.contains("TESI FINALE")
            let isIdoneita = (e.voto ?? "").lowercased().contains("idone")
            return !isOther && !isIdoneita
        }
        var weightedSum = 0, weightTot = 0
        for e in valid {
            let votoClean = e.voto?.replacingOccurrences(of: " e lode", with: "") ?? ""
            let votoVal = Int(votoClean.components(separatedBy: "/").first ?? "")
            let weight = Int(e.cfa ?? "")
            if let v = votoVal, let w = weight, w > 0 { weightedSum += v * w; weightTot += w }
        }
        let avgStr: String = (weightTot > 0) ? String(format: "%.1f", Double(weightedSum) / Double(weightTot)) : "-"

        let name = (self.displayName ?? "").isEmpty ? "LABA Firenze" : self.displayName!
        let summary = WidgetSummary(displayName: name, passed: passed, totalCFA: totalCFA, average: avgStr)

        if let data = try? JSONEncoder().encode(summary),
           let ud = UserDefaults(suiteName: LABA_APP_GROUP) {
            ud.set(data, forKey: "widget.summary")
            ud.synchronize()
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: "LABAWidget")
            #endif
        }
    }

    func signIn(username base: String, password: String) async {
        // Prepare email & base components
        let raw = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let email: String
        let baseOnly: String

        if Device.isMini {
            // On mini: allow either "nome.cognome" or full email. Avoid duplicate domain.
            let lower = raw.lowercased()
            if let at = lower.firstIndex(of: "@") {
                // User typed a full email → use it as-is for login, but keep base without domain for UI/storage
                email = lower
                baseOnly = String(lower[..<at])
            } else {
                // User typed only the base → append domain
                baseOnly = normalizeNameForEmail(raw)
                email = baseOnly + labaDomain
            }
        } else {
            // Non-mini: keep current behavior (always append domain)
            baseOnly = normalizeNameForEmail(raw)
            email = baseOnly + labaDomain
        }

        await MainActor.run { self.loading = true; self.error = nil }
        do {
            let token = try await APIClient.shared.loginROPC(email: email, password: password)
            await MainActor.run {
                self.accessToken = token.access_token
                self.isLoggedIn = true
                self.usernameBase = baseOnly
                let comps = baseOnly.split(separator: ".").map(String.init)
                if let first = comps.first { self.displayName = first.capitalized } else { self.displayName = baseOnly.capitalized }
            }
            self.setWidgetLoginState(true)
            await loadAll()
        } catch {
            await MainActor.run {
                self.error = "Utente o Password errata: Riprova!"
                self.loading = false
                self.isLoggedIn = false
            }
        }
    }

    func useManualToken(_ token: String) async {
        await MainActor.run {
            self.error = nil
            self.accessToken = token
            self.isLoggedIn = true
            self.loading = true
        }
        self.setWidgetLoginState(true)
        await loadAll()
    }

    @MainActor
    func restoreSession() async {
        guard !accessToken.isEmpty else { return }
        // Ripristina stato loggato
        self.isLoggedIn = true
        self.setWidgetLoginState(true)
        // Ricostruisci il displayName dal usernameBase (es. "nome.cognome" → "Nome")
        if self.displayName == nil || self.displayName?.isEmpty == true {
            let base = self.usernameBase
            let comps = base.split(separator: ".").map(String.init)
            if let first = comps.first { self.displayName = first.capitalized } else { self.displayName = base.capitalized }
        }
        // Carica subito i dati
        await self.loadAll()
    }

    func logout() {
        accessToken = ""
        esami = []
        isLoggedIn = false
        error = nil
        if let ud = UserDefaults(suiteName: LABA_APP_GROUP) {
            ud.removeObject(forKey: "widget.summary")
            ud.set(false, forKey: "user.isLoggedIn")
            ud.synchronize()
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "LABAWidget")
        #endif
    }

    func graduatedWord() -> String { (sesso ?? "").lowercased().hasPrefix("f") ? "Laureata" : "Laureato" }

    @MainActor
    func loadAll() async {
        guard !accessToken.isEmpty else { return }
        self.loading = true; self.error = nil
        defer { self.loading = false }
        do {
            let payload = try await APIClient.shared.enrollments(token: accessToken)
            let student = try await APIClient.shared.student(token: accessToken)
            self.studentOid = student.oid
            self.nome = student.nome
            self.cognome = student.cognome
            self.matricola = student.numMatricola
            self.sesso = student.sesso
            self.emailLABA = student.emailLABA
            self.emailPersonale = student.emailPersonale
            self.telefono = student.telefono
            self.cellulare = student.cellulare
            self.pagamenti = student.pagamenti
            if let n = student.nome, !n.isEmpty { self.displayName = n.capitalized }
            self.status = payload.stato
            self.currentYear = payload.annoAttuale
            self.pianoStudi = payload.pianoStudi
            self.esami = payload.situazioneEsami.map { r in
                Esame(
                    id: r.oidCorso,
                    corso: r.corso,
                    docente: r.docente,
                    anno: r.anno,
                    cfa: r.cfa,
                    propedeutico: r.propedeutico,
                    sostenutoIl: parseAPIDate(r.sostenutoIl),
                    voto: r.voto,
                    richiedibile: (r.richiedibile ?? "N").uppercased() == "S"
                )
            }
            self.updateWidgetSummary()
            if let semPayloads = try? await APIClient.shared.seminars(token: accessToken) {
                self.seminari = semPayloads.map { s in
                    Seminario(
                        id: s.seminarioOid,
                        titolo: s.descrizione,
                        descrizioneEstesa: s.descrizioneEstesa,
                        richiedibile: (s.richiedibile ?? "N").uppercased() == "S",
                        esito: s.esitoRichiesta
                    )
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func loadNotifications() async {
        guard !accessToken.isEmpty else { return }
        do {
            let notifPayloads = try await APIClient.shared.notifications(
                token: accessToken,
                studentOid: self.studentOid   // 👈 passa l’oid se c’è
            )
            var items: [NotificationItem] = notifPayloads.map { n in
                NotificationItem(
                    id: n.id,
                    title: n.oggetto,
                    message: n.messaggio,
                    createdAt: parseAPIDate(n.dataOraCreazione),
                    readAt: parseAPIDate(n.dataOraLetturaNotifica)
                )
            }
            // override locale “lette”
            items = items.map { it in
                var m = it
                if m.readAt == nil && localReadIDs.contains(m.id) { m.readAt = Date.distantPast }
                return m
            }
            items.sort { (a, b) in (a.createdAt ?? .distantPast) > (b.createdAt ?? .distantPast) }
            self.notifications = items
            print("Loaded notifications count = \(items.count)")
        } catch {
            print("Notifications load error: \(error)")
        }
    }

    func setNotification(_ id: Int, read: Bool) {
        var set = localReadIDs
        if read { set.insert(id) } else { set.remove(id) }
        localReadIDs = set
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            var item = notifications[idx]
            item.readAt = read ? (item.readAt ?? Date()) : nil
            notifications[idx] = item
        }
        Task { await APIClient.shared.markNotificationRead(token: accessToken, id: id) }
    }

    func markAllNotificationsRead() {
        notifications.enumerated().forEach { idx, it in
            notifications[idx].readAt = notifications[idx].readAt ?? Date()
        }
        localReadIDs = Set(notifications.map { $0.id })
    }
}

// MARK: - Common UI

struct Pill: View {
    enum Kind { case year, grade, cfa, status, alert }
    let text: String
    let kind: Kind
    var tintOverride: Color? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let base = tintOverride ?? baseColor(for: kind)
        let fillOpacity = scheme == .dark ? 0.22 : 0.16
        let strokeOpacity = scheme == .dark ? 0.55 : 0.30
        Text(text)
            .font(.caption)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(base.opacity(fillOpacity))
                    .overlay(
                        Capsule().stroke(base.opacity(strokeOpacity), lineWidth: 1)
                    )
            )
    }

    private func baseColor(for kind: Kind) -> Color {
        switch kind {
        case .year: return Color(.systemBlue)
        case .grade: return Color(.systemGreen)
        case .cfa: return Color(.systemOrange)
        case .status: return Color(.systemOrange)
        case .alert: return Color(.systemRed)
        }
    }
}


// MARK: - Animated Background for Login
struct AnimatedPatternBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0/15.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let base = Color(uiColor: .systemBackground)
                base
                    .overlay(pattern(in: geo.size, time: CGFloat(time)).opacity(0.20))
                    .ignoresSafeArea()
            }
        }
    }

    private func pattern(in size: CGSize, time: CGFloat) -> some View {
        Canvas { ctx, sz in
            let color: Color = (scheme == .dark) ? .white : Color.labaAccent.opacity(0.5)
            let step: CGFloat = 32
            let r: CGFloat = 2.5
            drawPattern(in: &ctx, size: sz, color: color, step: step, r: r, time: time)
        }
    }

    private func drawPattern(in ctx: inout GraphicsContext, size sz: CGSize, color: Color, step: CGFloat, r: CGFloat, time: CGFloat) {
        for y in stride(from: -step, through: sz.height + step, by: step) {
            for x in stride(from: -step, through: sz.width + step, by: step) {
                // Movimento pseudo-casuale e unico per ogni punto:
                let t = time * 0.6
                let seed = (x * 13 + y * 7)
                let dx = sin((x + y) / 140 + t * (1.2 + 0.17 * sin(seed))) * 10 * (0.8 + 0.3 * cos(seed))
                let dy = cos((x - y) / 120 + t * (1.3 + 0.23 * cos(seed + 99))) * 10 * (0.8 + 0.3 * sin(seed + 42))
                let rect = CGRect(x: x + dx, y: y + dy, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }
}

// MARK: - Login (SSO + fallback)
struct LoginView: View {
    @EnvironmentObject var vm: SessionVM
    @AppStorage("laba.usernameBase") private var storedUsername: String = ""

    @State private var userBase = ""
    @State private var password = ""
    @State private var showingInfo = false
    @State private var isLoading = false
    @State private var showManualToken = false
    @State private var manualToken = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var passwordVisible = false
    @FocusState private var focusedField: Field?
    @State private var startAnimations = false
    private enum Field { case user, password }
    // Easter Egg states
    @State private var showEasterEgg = false
    @State private var isLongPressing = false
    @State private var shakeOffset: CGFloat = 0
    @State private var hapticWork: DispatchWorkItem?
    @State private var shakeWork: DispatchWorkItem?
    // Timers for staged long-press (5s -> effects, 10s -> reveal)
    @State private var fiveWork: DispatchWorkItem?
    @State private var tenWork: DispatchWorkItem?

    var body: some View {
        NavigationStack {
            ZStack {
                if startAnimations {
                    AnimatedPatternBackground()
                        .transition(.opacity)
                }
                VStack(spacing: 20) {
                    // Logo with Easter Egg long press
                    Group {
                        Image(systemName: "graduationcap.circle.fill")
                            .font(.system(size: 88))
                            .foregroundStyle(Color.labaAccent)
                            .padding(.top, 36)
                            .offset(x: shakeOffset)
                            .contentShape(Rectangle())
                            .allowsHitTesting(true)
                            .onLongPressGesture(minimumDuration: 10, perform: {
                                // 10s reached: stop effects and reveal
                                stopHaptics()
                                stopShake()
                                withAnimation(.easeInOut(duration: 0.25)) { showEasterEgg = true }
                                isLongPressing = false
                            }, onPressingChanged: { pressing in
                                if pressing {
                                    // finger down -> arm the staged timers
                                    isLongPressing = true
                                    // cancel leftover timers just in case
                                    fiveWork?.cancel(); tenWork?.cancel()

                                    let five = DispatchWorkItem {
                                        if isLongPressing {
                                            startEscalatingHaptics()
                                            startEscalatingShake()
                                        }
                                    }
                                    fiveWork = five
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: five)

                                    let ten = DispatchWorkItem {
                                        if isLongPressing {
                                            stopHaptics()
                                            stopShake()
                                            withAnimation(.easeInOut(duration: 0.25)) { showEasterEgg = true }
                                            isLongPressing = false
                                        }
                                    }
                                    tenWork = ten
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: ten)

                                } else {
                                    // finger lifted or gesture cancelled
                                    isLongPressing = false
                                    fiveWork?.cancel(); fiveWork = nil
                                    tenWork?.cancel(); tenWork = nil
                                    stopHaptics()
                                    stopShake()
                                }
                            })
                    }

                    Text("LABA Firenze")
                        .font(.largeTitle).bold()

                    // Inputs
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill").foregroundStyle(.secondary)
                            TextField("nome.cognome", text: $userBase)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .user)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                            if !Device.isMini {
                                Text("@labafirenze.com").foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 60).fill(Color.cardBG))

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill").foregroundStyle(.secondary)
                            if passwordVisible {
                                TextField("Password", text: $password)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit { Task { await doLogin() } }
                            } else {
                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit { Task { await doLogin() } }
                            }
                            Spacer()
                            Button(action: {
                                passwordVisible.toggle()
                                DispatchQueue.main.async { focusedField = .password }
                            }) { Image(systemName: passwordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 60).fill(Color.cardBG))
                    }
                    .padding(.horizontal)

                    if let err = vm.error, !err.isEmpty {
                        Text(err).font(.footnote).foregroundStyle(.red)
                    }

                    Button(action: { Task { await doLogin() } }) {
                        if vm.loading || isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Entra")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 30) // più largo e alto
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.labaAccent)
                    .font(.headline)
                    .padding(.horizontal, 12) // margine laterale
                    .buttonBorderShape(.roundedRectangle(radius: 50))
                    .disabled(userBase.isEmpty || password.isEmpty || vm.loading || isLoading)

                    Spacer(minLength: 16)

                    Text("© 2025 LABA Firenze - with 💙 by Simone Azzinelli")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingInfo = true } label: { Image(systemName: "info.circle") }
                }

            }
            .sheet(isPresented: $showingInfo) {
                AccessHelpSheet()
                    .presentationDetents([.large, .medium])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                if !storedUsername.isEmpty { userBase = storedUsername }
                // Warm up common SF Symbols once so tab bar icons render instantly later
                warmUpSymbols()
                // Defer animated background slightly to avoid fighting with first-frame UI work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.25)) { startAnimations = true }
                }
            }
            .fullScreenCover(isPresented: $showEasterEgg) {
                LABAEggView(onClose: { showEasterEgg = false })
                    .transition(.opacity)
            }
        }
    }

    private func doLogin() async {
        isLoading = true
        defer { isLoading = false }
        await vm.signIn(username: userBase, password: password)
    }

    // MARK: - Escalation Haptics (5s..10s)
    private func startEscalatingHaptics() {
        stopHaptics()
        var work: DispatchWorkItem! // predeclare so the closure can reference it
        work = DispatchWorkItem {
            let start = Date()
            func step() {
                guard isLongPressing, work != nil, !work.isCancelled else { return }
                let elapsed = Date().timeIntervalSince(start)
                guard elapsed < 5.0 else { return } // runs only during 5..10s window

                // progress 0..1
                let t = max(0, min(1, elapsed / 5.0))
                // interval ramps from slow(0.6s) to fast(0.06s)
                let interval = 0.6 - (0.54 * t)
                // haptic style increases over time
                let style: UIImpactFeedbackGenerator.FeedbackStyle = t > 0.7 ? .heavy : (t > 0.35 ? .medium : .light)
                let gen = UIImpactFeedbackGenerator(style: style)
                gen.impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + interval) { step() }
            }
            step()
        }
        hapticWork = work
        DispatchQueue.main.async(execute: work)
    }

    private func stopHaptics() {
        hapticWork?.cancel()
        hapticWork = nil
    }

    // MARK: - Escalation Shake (ampiezza/frequenza crescenti 5s..10s)
    private func startEscalatingShake() {
        stopShake()
        var work: DispatchWorkItem! // predeclare so the closure can reference it
        work = DispatchWorkItem {
            let start = Date()
            func step() {
                guard isLongPressing, work != nil, !work.isCancelled else { shakeOffset = 0; return }
                let elapsed = Date().timeIntervalSince(start)
                guard elapsed < 5.0 else { shakeOffset = 0; return }

                // progress 0..1
                let t = max(0, min(1, elapsed / 5.0))
                // amplitude from 0pt to 14pt
                let amplitude: CGFloat = 14 * t
                // frequency grows: period from 0.18s down to 0.06s
                let period = 0.18 - (0.12 * t)

                withAnimation(.easeInOut(duration: period/2)) { shakeOffset = amplitude }
                DispatchQueue.main.asyncAfter(deadline: .now() + period/2) {
                    withAnimation(.easeInOut(duration: period/2)) { shakeOffset = -amplitude }
                    DispatchQueue.main.asyncAfter(deadline: .now() + period/2) { step() }
                }
            }
            step()
        }
        shakeWork = work
        DispatchQueue.main.async(execute: work)
    }

    private func stopShake() {
        shakeWork?.cancel()
        shakeWork = nil
        shakeOffset = 0
    }
}

struct AccessHelpSheet: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 8) {
            // Grabber neutro (rispetta Light/Dark)
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 6)

            Text("Assistenza")
                .font(.title2).bold()
                .padding(.top, 2)
            Spacer().frame(height: 6)

            List {
                // Guida rapida
                Section("Guida rapida") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Accedi utilizzando nome.cognome", systemImage: "at")
                        Label("Controlla maiuscole/minuscole", systemImage: "textformat")
                        Label("Evita spazi iniziali/finali nei campi", systemImage: "rectangle.and.pencil.and.ellipsis")
                        Label("Hai appena cambiato password? Attendi un po'", systemImage: "clock")
                    }
                    .font(.subheadline)
                }

                // Recupero credenziali — stile riga standard (no pulsante blu)
                Section("Recupero credenziali") {
                    Button {
                        let subject = "Assistenza accesso"
                        let body = "Nome e cognome:%0A Matricola:%0A Dispositivo: iPhone/iPad%0A Versione iOS:%0A%0A Descrizione problema:%0A"
                        let urlString = "mailto:info@laba.biz?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)&body=\(body)"
                        if let url = URL(string: urlString) { openURL(url) }
                    } label: {
                        HStack {
                            Label("Richiedi reset password", systemImage: "key.fill")
                            Spacer(minLength: 8)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Link utili — Sito e numeri (NO privacy policy)
                Section("Link utili") {
                    Link(destination: URL(string: "https://www.laba.biz")!) {
                        Label("Sito LABA", systemImage: "globe")
                    }
                    Button {
                        if let url = URL(string: "tel://0556530786") { openURL(url) }
                    } label: {
                        HStack {
                            Label("Chiama Segreteria Didattica", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                    }
                    .tint(.blue)
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: "tel://3343824934") { openURL(url) }
                    } label: {
                        HStack {
                            Label("Reparto IT", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                    }
                    .tint(.blue)
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .padding(.bottom, 0)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}


struct NotificheView: View {
    @EnvironmentObject var vm: SessionVM
    @State private var showOnlyUnread = false

    private var list: [NotificationItem] {
        showOnlyUnread ? vm.notifications.filter { !$0.isRead } : vm.notifications
    }

    var body: some View {
        List {
            if list.isEmpty {
                Section {
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView(
                            "Nessuna comunicazione",
                            systemImage: "bell.slash",
                            description: Text("Le comunicazioni dall'accademia appariranno qui."))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "bell.slash").font(.largeTitle).foregroundStyle(.secondary)
                            Text("Nessuna comunicazione").font(.headline)
                            Text("Le comunicazioni dall'accademia appariranno qui.").font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
            } else {
                Section {
                    ForEach(list) { n in
                        HStack(alignment: .top, spacing: 10) {
                            if !(n.isRead) { Circle().fill(Color.labaAccent).frame(width: 8, height: 8).padding(.top, 7) }
                            VStack(alignment: .leading, spacing: 4) {
                                // Titolo: solo il nome della materia in bold (titolo-cased)
                                Text(parsedCourse(from: n.message))
                                    .font(.body).bold()

                                // Sottotitolo fisso richiesto: "Inserita dispensa"
                                Text("Inserita dispensa")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                // Data/ora
                                if let d = n.createdAt {
                                    Text(itDateTime(d))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if n.isRead {
                                Button { vm.setNotification(n.id, read: false) } label: { Label("Segna come non letta", systemImage: "envelope.badge") }
                                    .tint(.orange)
                            } else {
                                Button { vm.setNotification(n.id, read: true) } label: { Label("Segna come letta", systemImage: "checkmark") }
                                    .tint(.green)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Avvisi")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.notifications.isEmpty {
                    Menu {
                        Toggle(isOn: $showOnlyUnread) { Label("Mostra solo non lette", systemImage: "envelope.badge") }
                        Button(role: .none) { vm.markAllNotificationsRead() } label: { Label("Segna tutte come lette", systemImage: "checkmark.circle") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .refreshable {
            await vm.loadNotifications()
        }
        .task { await vm.loadNotifications() }
    }

    private func parsedCourse(from message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

        // Regex per pattern tipico: "Dispensa di <MATERIA> inserita"
        if let re = try? NSRegularExpression(pattern: "(?i)Dispensa di\\s+(.+?)\\s+inserita"),
           let match = re.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           match.numberOfRanges >= 2,
           let r = Range(match.range(at: 1), in: trimmed) {
            let raw = String(trimmed[r])
            return prettifyTitle(raw)
        }

        // Fallback: rimuovi eventuali prefissi/suffissi ricorrenti
        var guess = trimmed
        if guess.lowercased().hasPrefix("dispensa di ") {
            guess = String(guess.dropFirst("dispensa di ".count))
        }
        if guess.lowercased().hasSuffix(" inserita") {
            guess = String(guess.dropLast(" inserita".count))
        }
        return prettifyTitle(guess)
    }
}

// MARK: - Esami

struct ExamsView: View {
    @EnvironmentObject var vm: SessionVM
    @State private var selectedYear: Int = 0 // 0 = tutti (chips)
    @State private var statusFilter: StatusFilter = .all
    @State private var queryRaw: String = ""
    @State private var query: String = ""
    @State private var debounceItem: DispatchWorkItem? = nil
    @Environment(\.colorScheme) private var colorScheme

    private enum StatusFilter: CaseIterable { case all, passed, pending }

    private let years: [Int] = [1, 2, 3]
    private var filteredByYear: [Esame] { vm.esami.filter { $0.anno == selectedYear } }
    private var filteredByStatus: [Esame] {
        switch statusFilter {
        case .all: return filteredByYear
        case .passed: return filteredByYear.filter { !($0.voto ?? "").isEmpty }
        case .pending: return filteredByYear.filter { ($0.voto ?? "").isEmpty }
        }
    }
    private var filtered: [Esame] {
        // Base già filtrata (per anno/stato) — usa l’array che stai mostrando nel body
        let base = filteredByYear   // <-- se nel tuo codice è un altro nome, metti quello

        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return base }

        let qLower = q.lowercased()
        let numericQuery: Int? = {
            let digits = q.filter { $0.isNumber }
            return digits.isEmpty ? nil : Int(digits)
        }()

        return base.filter { e in
            // Titolo corso o docente
            if prettifyTitle(e.corso).localizedCaseInsensitiveContains(q) { return true }
            if (e.docente ?? "").localizedCaseInsensitiveContains(q) { return true }

            // Ricerca per voto numerico (es. "28" -> 28/30)
            if let want = numericQuery, let got = voteNumber(from: e.voto), want == got { return true }

            // Ricerca per idoneità
            if qLower.contains("idone"), isIdoneitaVote(e.voto) { return true }

            return false
        }
    }

    private var statusTitle: String {
        switch statusFilter {
        case .all: return "Tutti"
        case .passed: return "Sostenuti"
        case .pending: return "Non sostenuti"
        }
    }

    private func isOther(_ e: Esame) -> Bool {
        let t = e.corso.lowercased()
        return t.contains("attivit") || t.contains("tesi")
    }

    // Estrae il numero di voto (es. "28/30" -> 28); nil se non presente
    private func voteNumber(from voto: String?) -> Int? {
        guard let v = voto?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return nil }
        let comps = v.components(separatedBy: "/")
        if let first = comps.first?.trimmingCharacters(in: .whitespaces),
           let n = Int(first) { return n }
        return nil
    }

    // True se il voto è un'esito di idoneità
    private func isIdoneitaVote(_ voto: String?) -> Bool {
        guard let v = voto?.lowercased() else { return false }
        return v.contains("idoneo") || v.contains("idonea") || v.contains("idoneità")
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Anno", selection: $selectedYear) {
                        ForEach(years, id: \.self) { y in
                            Text(italianOrdinalYear(y)).tag(y)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.labaAccent)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section {
                    ForEach(filtered.filter { !isOther($0) }) { e in
                        NavigationLink { ExamDetailView(esame: e).environmentObject(vm) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prettifyTitle(e.corso)).font(.body).bold()
                                if let docente = e.docente, !docente.isEmpty { Text(docente).font(.subheadline).foregroundStyle(.secondary) }
                                HStack(spacing: 8) {
                                    if let a = e.anno { Pill(text: italianOrdinalYear(a), kind: .year, tintOverride: yearTint(a)) }
                                    // Stato di questo esame
                                    if let v = e.voto, !v.isEmpty {
                                        Pill(text: v, kind: .grade)
                                    } else {
                                        Pill(text: "Da sostenere", kind: .alert)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }

                let workshops = filtered.filter { $0.corso.uppercased().contains("ATTIVITA' A SCELTA") }
                if !workshops.isEmpty {
                    Section {
                        ForEach(workshops) { e in
                            NavigationLink { ExamDetailView(esame: e).environmentObject(vm) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prettifyTitle(e.corso)).font(.body).bold()
                                    if let docente = e.docente, !docente.isEmpty { Text(docente).font(.subheadline).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    } header: {
                        Text("Workshop / Seminari / Tirocinio")
                    }
                }

                let thesis = filtered.filter { $0.corso.uppercased().contains("TESI FINALE") }
                if !thesis.isEmpty {
                    Section {
                        ForEach(thesis) { e in
                            NavigationLink { ExamDetailView(esame: e).environmentObject(vm) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prettifyTitle(e.corso)).font(.body).bold()
                                    if let docente = e.docente, !docente.isEmpty { Text(docente).font(.subheadline).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    } header: {
                        Text("Tesi Finale")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .navigationTitle("Esami")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $queryRaw, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca esami")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .onChange(of: queryRaw) { _, newValue in
                debounceItem?.cancel()
                let w = DispatchWorkItem {
                    self.query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                debounceItem = w
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: w)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Stato", selection: $statusFilter) {
                            Text("Tutti").tag(StatusFilter.all)
                            Text("Sostenuti").tag(StatusFilter.passed)
                            Text("Non sostenuti").tag(StatusFilter.pending)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(statusTitle)
                        }
                        .tint(Color.labaAccent)
                    }
                }
            }
            .onAppear {
                if selectedYear == 0 { selectedYear = vm.currentYear ?? 1 }
            }
            .animation(nil, value: statusFilter)
            .animation(nil, value: selectedYear)
            .animation(nil, value: query)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct ExamDetailView: View {
    let esame: Esame
    @EnvironmentObject var vm: SessionVM
    @State private var showBookingAlert = false

    var body: some View {
        List {
            Section {
                HStack { Text("Materia"); Spacer(); Text(prettifyTitle(esame.corso)).multilineTextAlignment(.trailing) }
                if let d = esame.docente { HStack { Text("Docente"); Spacer(); Text(d).multilineTextAlignment(.trailing) } }
                if let a = esame.anno { HStack { Text("Anno" ); Spacer(); Text(italianOrdinalYear(a)) } }
                if let cfa = esame.cfa { HStack { Text("CFA"); Spacer(); Text(cfa) } }
                if let d = esame.sostenutoIl { HStack { Text("Data"); Spacer(); Text(ddMMyyyy(d)) } }
                if let v = esame.voto, !v.isEmpty { HStack { Text("Voto"); Spacer(); Text(v) } }
            } header: {
                Text("Dettagli")
            }
            
            if let prev = vm.esami.first(where: { ($0.propedeutico ?? "").uppercased().contains(esame.corso.uppercased()) }) {
                Section {
                    HStack {
                        let passed = !(prev.voto ?? "").isEmpty
                        Image(systemName: passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(passed ? .green : .orange)
                        VStack(alignment: .leading) {
                            Text(prettifyTitle(prev.corso)).bold()
                            if let v = prev.voto, !v.isEmpty {
                                Text("Voto: \(v)").font(.footnote).foregroundStyle(.secondary)
                            }
                            if (prev.voto ?? "").isEmpty {
                                Pill(text: "Da sostenere", kind: .alert)
                            }
                        }
                    }
                } header: {
                    Text("Precedente richiesto")
                } footer: {
                    Text("È necessario aver superato questo esame per poter prenotare \(prettifyTitle(esame.corso)).")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }


            if let p = esame.propedeutico, !p.isEmpty {
                let clean = p.replacingOccurrences(of: "Corso propedeutico per ", with: "")
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(prettifyTitle(clean)).bold()
                    }
                    .accessibilityLabel("Propedeuticità: \(prettifyTitle(clean))")
                } header: {
                    Text("Propedeuticità")
                } footer: {
                    Text("Superando \(prettifyTitle(esame.corso)) potrai prenotare i corsi indicati di seguito.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            
            Section {
                if esame.richiedibile {
                    Button { showBookingAlert = true } label: { Label("Prenota ora", systemImage: "calendar.badge.plus") }
                } else {
                    Text("Prenotazione non disponibile").foregroundStyle(.secondary)
                }
            } header: {
                Text("Prenotazione")
            }
        }
        .navigationTitle("Dettagli esame")
        .navigationBarTitleDisplayMode(.large)
        .alert("Prenotazione", isPresented: $showBookingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Collegheremo qui l'endpoint di prenotazione appena disponibile.")
        }
    }
}

// MARK: - Corsi

struct CorsiView: View {
    @EnvironmentObject var vm: SessionVM
    @Environment(\.openURL) private var openURL
    @State private var selectedYear: Int = 0 // 0 = tutti
    @State private var mailPulse: Bool = false
    @State private var query: String = ""
    @Environment(\.colorScheme) private var colorScheme

    private var years: [Int] { let ys = Set(vm.esami.compactMap { $0.anno }); return [0] + ys.sorted() }
    private var filteredByYear: [Esame] { selectedYear == 0 ? vm.esami : vm.esami.filter { $0.anno == selectedYear } }
    // Estrae il numero di voto (es. "28/30" -> 28); restituisce nil se non presente
    private func voteNumber(from voto: String?) -> Int? {
        guard let v = voto?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return nil }
        // Formato tipico: "28/30" oppure "30 / 30" ecc.
        let comps = v.components(separatedBy: "/")
        if let first = comps.first?.trimmingCharacters(in: .whitespaces), let n = Int(first) { return n }
        return nil
    }

    // True se il voto rappresenta un'idoneità
    private func isIdoneitaVote(_ voto: String?) -> Bool {
        guard let v = voto?.lowercased() else { return false }
        return v.contains("idoneo") || v.contains("idonea") || v.contains("idoneità")
    }

    private var filtered: [Esame] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return filteredByYear }
        let qLower = q.lowercased()
        let numericQuery: Int? = {
            let digits = q.filter({ $0.isNumber })
            return digits.isEmpty ? nil : Int(digits)
        }()

        return filteredByYear.filter { c in
            // 1) titolo corso o docente
            if prettifyTitle(c.corso).localizedCaseInsensitiveContains(q) { return true }
            if (c.docente ?? "").localizedCaseInsensitiveContains(q) { return true }
            // 2) ricerca per voto numerico (es. "28" → trova 28/30)
            if let want = numericQuery, let got = voteNumber(from: c.voto), want == got { return true }
            // 3) ricerca per idoneità (query contiene "idoneo/a/ità")
            if qLower.contains("idone"), isIdoneitaVote(c.voto) { return true }
            return false
        }
    }

    private func isOther(_ e: Esame) -> Bool {
        let t = e.corso.lowercased()
        return t.contains("attivit") || t.contains("tesi")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(filtered.filter { !isOther($0) }) { c in
                        NavigationLink {
                            CourseDetailView(corso: c).environmentObject(vm)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prettifyTitle(c.corso)).font(.body).bold().lineLimit(2)
                                if let d = c.docente, !d.isEmpty { Text(d).font(.subheadline).foregroundStyle(.secondary) }
                                HStack(spacing: 8) {
                                    if let a = c.anno { Pill(text: italianOrdinalYear(a), kind: .year, tintOverride: yearTint(a)) }
                                    if let cfa = c.cfa, !cfa.isEmpty { Pill(text: "CFA \(cfa)", kind: .cfa) }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if let docente = c.docente, let first = teacherEmails(from: docente).first,
                               let url = URL(string: "mailto:\(first)") {
                                Button { openURL(url) } label: { Label("Invia mail", systemImage: "envelope.fill") }
                                    .tint(Color.labaAccent)
                            }
                        }
                    }
                }

                let workshops = filtered.filter { $0.corso.uppercased().contains("ATTIVITA' A SCELTA") }
                if !workshops.isEmpty {
                    Section {
                        ForEach(workshops) { c in
                            NavigationLink {
                                CourseDetailView(corso: c).environmentObject(vm)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prettifyTitle(c.corso)).font(.body).bold().lineLimit(2)
                                    if let d = c.docente, !d.isEmpty { Text(d).font(.subheadline).foregroundStyle(.secondary) }
                                    HStack(spacing: 8) {
                                        if let a = c.anno { Pill(text: italianOrdinalYear(a), kind: .year, tintOverride: yearTint(a)) }
                                        if let cfa = c.cfa, !cfa.isEmpty { Pill(text: "CFA \(cfa)", kind: .cfa) }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if let docente = c.docente, let first = teacherEmails(from: docente).first,
                                   let url = URL(string: "mailto:\(first)") {
                                    Button { openURL(url) } label: { Label("Invia mail", systemImage: "envelope.fill") }
                                        .tint(Color.labaAccent)
                                }
                            }
                        }
                    } header: {
                        Text("Workshop / Seminari / Tirocinio")
                    }
                }

                let thesis = filtered.filter { $0.corso.uppercased().contains("TESI FINALE") }
                if !thesis.isEmpty {
                    Section {
                        ForEach(thesis) { c in
                            NavigationLink {
                                CourseDetailView(corso: c).environmentObject(vm)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prettifyTitle(c.corso)).font(.body).bold().lineLimit(2)
                                    if let d = c.docente, !d.isEmpty { Text(d).font(.subheadline).foregroundStyle(.secondary) }
                                    HStack(spacing: 8) {
                                        if let a = c.anno { Pill(text: italianOrdinalYear(a), kind: .year, tintOverride: yearTint(a)) }
                                        if let cfa = c.cfa, !cfa.isEmpty { Pill(text: "CFA \(cfa)", kind: .cfa) }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if let docente = c.docente, let first = teacherEmails(from: docente).first,
                                   let url = URL(string: "mailto:\(first)") {
                                    Button { openURL(url) } label: { Label("Invia mail", systemImage: "envelope.fill") }
                                        .tint(Color.labaAccent)
                                }
                            }
                        }
                    } header: {
                        Text("Tesi Finale")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .navigationTitle("Corsi")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca corsi")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Anno", selection: $selectedYear) {
                            Text("Tutti").tag(0)
                            ForEach(years.filter { $0 != 0 }, id: \.self) { y in Text(italianOrdinalYear(y)).tag(y) }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedYear == 0 ? "Tutti" : italianOrdinalYear(selectedYear))
                        }
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}


struct CourseDetailView: View {
    @EnvironmentObject var vm: SessionVM
    @Environment(\.openURL) private var openURL
    let corso: Esame
    @Environment(\.colorScheme) private var colorScheme

    private var docenteEmail: String? {
        guard let d = corso.docente else { return nil }
        return teacherEmails(from: d).first
    }

    // Questo corso è propedeutico per...
    private var nextCourses: [String] {
        if let p = corso.propedeutico {
            let clean = p.replacingOccurrences(of: "Corso propedeutico per ", with: "").trimmingCharacters(in: .whitespaces)
            return clean.isEmpty ? [] : [clean]
        }
        return []
    }

    // Per questo corso è richiesto aver sostenuto...
    private var previousRequired: Esame? {
        vm.esami.first { e in
            let target = corso.corso.uppercased()
            let p = (e.propedeutico ?? "").uppercased()
            return p.contains(target)
        }
    }

    var body: some View {
        List {
            Section {
                HStack { Text("Materia"); Spacer(); Text(prettifyTitle(corso.corso)).multilineTextAlignment(.trailing) }
                if let d = corso.docente { HStack { Text("Docente"); Spacer(); Text(d).multilineTextAlignment(.trailing) } }
                if let a = corso.anno { HStack { Text("Anno"); Spacer(); Text(italianOrdinalYear(a)) } }
                if let cfa = corso.cfa { HStack { Text("CFA"); Spacer(); Text(cfa) } }
            } header: {
                Text("Dettagli corso")
            }
            
            if let prev = previousRequired {
                Section {
                    HStack {
                        let passed = !(prev.voto ?? "").isEmpty
                        Image(systemName: passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(passed ? .green : .orange)
                        VStack(alignment: .leading) {
                            Text(prettifyTitle(prev.corso)).bold()
                            if let v = prev.voto, !v.isEmpty {
                                Text("Voto: \(v)").font(.footnote).foregroundStyle(.secondary)
                            }
                            if (prev.voto ?? "").isEmpty {
                                Pill(text: "Da sostenere", kind: .alert)
                            }
                        }
                    }
                } header: {
                    Text("Precedente richiesto")
                } footer: {
                    Text("Devi aver superato questo esame per poter prenotare \(prettifyTitle(corso.corso)).")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if !nextCourses.isEmpty {
                Section {
                    ForEach(nextCourses, id: \.self) { name in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            Text(prettifyTitle(name)).bold()
                        }
                    }
                } header: {
                    Text("Propedeuticità")
                } footer: {
                    Text("Superando \(prettifyTitle(corso.corso)) potrai prenotare gli esami elencati.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            if let email = docenteEmail, let url = URL(string: "mailto:\(email)") {
                Section {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Invia mail al docente", systemImage: "envelope.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .padding(.vertical, 0)
                    .tint(Color.labaAccent)
                }
            }
        }
        .navigationTitle("Dettagli corso")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Seminari

struct SeminariView: View {
    @EnvironmentObject var vm: SessionVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var query: String = ""
    private var filtered: [Seminario] {
        guard !query.isEmpty else { return vm.seminari }
        return vm.seminari.filter { prettifyTitle(seminarTitle(from: $0.titolo)).localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        NavigationStack {
            List {
                if vm.seminari.isEmpty {
                    Section {
                        Text("Nessun seminario disponibile").foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(filtered) { s in
                            NavigationLink { SeminarioDetailView(seminario: s) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prettifyTitle(seminarTitle(from: s.titolo))).font(.body).bold().lineLimit(3)
                                    if s.richiedibile { Pill(text: "Prenotabile", kind: .grade) }
                                }
                            }
                        }

                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Seminari")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca seminari")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct SeminarioDetailView: View {
    let seminario: Seminario
    @State private var showBookingAlert = false
    @Environment(\.colorScheme) private var colorScheme

    private var details: SeminarDetails { parseSeminarDetails(html: seminario.descrizioneEstesa, esito: seminario.esito) }

    var body: some View {
        List {
            if let docente = details.docente, !docente.isEmpty {
                Section {
                    Text(docente)
                } header: {
                    Text("Docente")
                }
            }
            if !details.dateLines.isEmpty {
                Section {
                    ForEach(details.dateLines, id: \.self) { Text($0) }
                } header: {
                    Text("Date")
                }
            }
            if let aula = details.aula, !aula.isEmpty {
                Section {
                    Text(aula)
                } header: {
                    Text("Aula")
                }
            }
            if let all = details.allievi, !all.isEmpty {
                Section {
                    let groups = allieviGroups(from: all)
                    if groups.isEmpty {
                        Text(all)
                    } else {
                        ForEach(0..<groups.count, id: \.self) { i in
                            let g = groups[i]
                            HStack(spacing: 8) {
                                if let y = g.anno { Pill(text: italianOrdinalYear(y), kind: .year, tintOverride: yearTint(y)) }
                                if let c = g.corso { Pill(text: c, kind: .status) }
                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Disponibile per:")
                }
            }
            
            if !details.groups.isEmpty {
                Section {
                    ForEach(details.groups.indices, id: \.self) { i in
                        let g = details.groups[i]
                        HStack {
                            Text("GRUPPO \(g.label):").bold()
                            Spacer()
                            Text(g.time.isEmpty ? "—" : g.time)
                        }
                    }
                } header: {
                    Text("Gruppi e orari")
                }
            }
            
            if let cfa = details.cfa, !cfa.isEmpty {
                Section {
                    Text(cfa)
                } header: {
                    Text("CFA acquisibili")
                }
            }
            if let ass = details.assenze, !ass.isEmpty {
                Section {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange); Text(ass) }
                } header: {
                    Text("Assenze consentite")
                }
            }
            if details.completed {
                Section {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        Text("Seminario conseguito")
                    }
                }
            }
            Section {
                if seminario.richiedibile {
                    Button { showBookingAlert = true } label: { Label("Prenota ora", systemImage: "calendar.badge.plus") }
                } else { Text("Prenotazione non disponibile").foregroundStyle(.secondary) }
            } header: {
                Text("Prenotazione")
            }
        }
        .navigationTitle("Dettagli seminario")
        .navigationBarTitleDisplayMode(.large)
        .alert("Prenotazione", isPresented: $showBookingAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Collegheremo qui l'endpoint di prenotazione appena disponibile.") }
    }
}

// MARK: - Profilo (minimal, keeps earlier behavior)

struct ProfilePill: View {
    let text: String
    let systemName: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName).font(.caption2)
            Text(text).font(.caption)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(Color.cardBG))
    }
}

struct ProfiloView: View {
    @EnvironmentObject var vm: SessionVM
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    @State private var isRefreshing: Bool = false
    @State private var didJustRefresh: Bool = false
    @State private var showLogoutConfirm: Bool = false
    @AppStorage("laba.usernameBase") private var usernameBase: String = ""
    @AppStorage("laba.notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("laba.theme") private var themePreference: String = "system"
    @AppStorage("laba.accent") private var accentChoice: String = "system"
    @AppStorage("laba.avatarData") private var avatarData: Data = Data()
    @Environment(\.colorScheme) private var colorScheme

    // Image derived from persisted avatar data (if any)
    private var avatarImage: Image? {
        guard !avatarData.isEmpty, let ui = UIImage(data: avatarData) else { return nil }
        return Image(uiImage: ui)
    }

    private func requestNotificationPermission() {
        // Verifica stato corrente, poi richiedi se necessario
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            #if canImport(UIKit)
                            UIApplication.shared.registerForRemoteNotifications()
                            #endif
                            notificationsEnabled = true
                        } else {
                            notificationsEnabled = false
                        }
                    }
                }
            case .denied:
                // Permesso negato a livello di sistema → ripristina toggle a OFF
                DispatchQueue.main.async { notificationsEnabled = false }
            case .authorized, .provisional, .ephemeral:
                // Già autorizzato → assicurati che APNs sia registrato
                DispatchQueue.main.async {
                    #if canImport(UIKit)
                    UIApplication.shared.registerForRemoteNotifications()
                    #endif
                    notificationsEnabled = true
                }
            @unknown default:
                break
            }
        }
    }

    @MainActor
    private func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // Re-run the full bootstrap (come allo startup) e poi ricarica notifiche esplicite
        await vm.restoreSession()
        await vm.loadNotifications()

        // Feedback utente
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        didJustRefresh = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            didJustRefresh = false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            Button { showPhotoPicker = true } label: {
                                if let img = (profileImage ?? avatarImage) {
                                    img.resizable().scaledToFill().frame(width: 56, height: 56).clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill").font(.system(size: 56)).foregroundStyle(colorScheme == .dark ? .white : Color.labaAccent)
                                        .frame(width: 56, height: 56)
                                }
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading) {
                                Text(
                                    {
                                        let combined = [vm.nome, vm.cognome].compactMap { $0 }.joined(separator: " ")
                                        if combined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            return fullName(from: usernameBase.isEmpty ? (vm.displayName ?? "") : usernameBase)
                                        } else {
                                            return combined
                                        }
                                    }()
                                )
                                .font(.title3).bold()
                            }
                        }

                        HStack(spacing: 8) {
                            if let p = vm.pagamenti {
                                let ok = p.uppercased() == "OK"
                                Pill(text: ok ? "Pagamenti in regola" : "Pagamenti non in regola",
                                     kind: ok ? .grade : .alert)
                            }
                            ProfilePill(text: "Matricola: \(vm.matricola ?? "—")", systemName: "number")
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }

                Section {
                    NavigationLink { MaterialiView() } label: {
                        Label("Materiali", systemImage: "doc.on.doc.fill")
                    }
                    NavigationLink { DocumentiView() } label: {
                        Label("Documenti", systemImage: "doc.text.fill")
                    }
                    NavigationLink { RegolamentiView() } label: {
                        Label("Regolamenti", systemImage: "book.closed.fill")
                    }
                } header: {
                    Text("Risorse")
                }

                Section {
                    NavigationLink { FAQView().environmentObject(vm) } label: {
                        Label("Consulta FAQ", systemImage: "questionmark.circle.fill")
                    }
                } header: {
                    Text("Assistenza")
                }

                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Notifiche", systemImage: "bell.fill")
                    }
                    .tint(Color.labaAccent)

                    NavigationLink { AppearanceSettingsView() } label: {
                        Label("Aspetto", systemImage: "paintbrush.fill")
                    }
                } header: {
                    Text("Preferenze")
                }

                Section {
                    Link(destination: URL(string: "mailto:info@laba.biz")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color.labaAccent) // icona = accent
                            Text("Scrivi alla Segreteria")
                                .foregroundColor(colorScheme == .dark ? .white : .primary) // testo: bianco in dark, default in light
                        }
                    }
                    Link(destination: URL(string: "https://wa.me/393316392105")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "ellipsis.message.fill")
                                .foregroundColor(Color(red: 37/255, green: 185/255, blue: 102/255)) // WhatsApp green
                            Text("Scrivi su WhatsApp")
                                .foregroundColor(Color(red: 37/255, green: 185/255, blue: 102/255)) // WhatsApp green
                        }
                    }
                    Link(destination: URL(string: "https://www.laba.biz")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .foregroundColor(Color.labaAccent)
                            Text("Sito web LABA")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                    }
                    Link(destination: URL(string: "https://www.laba.biz/privacy-policy")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(Color.labaAccent)
                            Text("Privacy Policy")
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                        }
                    }
                } header: {
                    Text("Link utili")
                }
                Section {
                    // Ricarica dati — mostra spinner durante refresh, disabilita durante refresh
                    Button {
                        Task { await refreshAll() }
                    } label: {
                        HStack(spacing: 8) {
                            if isRefreshing {
                                ProgressView().progressViewStyle(.circular)
                            } else {
                                Image(systemName: "arrow.clockwise.circle.fill")
                            }
                            Text(isRefreshing ? "Aggiorno…" : "Ricarica dati")
                        }
                        .foregroundColor(Color.labaAccent)
                    }
                    .disabled(isRefreshing)

                    // Esci — rosso: icona + testo
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        vm.logout()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                            Text("Esci")
                        }
                        .foregroundColor(.red)
                    }
                    .alert("Vuoi davvero uscire?", isPresented: $showLogoutConfirm) {
                        Button("Annulla", role: .cancel) {}
                        Button("Esci", role: .destructive) { vm.logout() }
                    }
                }
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.large)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    // Try to get raw Data, then normalize to JPEG to reduce size and ensure compatibility
                    if let raw = try? await item.loadTransferable(type: Data.self),
                       let ui = UIImage(data: raw) {
                        if let jpeg = ui.jpegData(compressionQuality: 0.9) {
                            avatarData = jpeg
                        } else if let png = ui.pngData() {
                            avatarData = png
                        } else {
                            avatarData = raw
                        }
                        profileImage = Image(uiImage: ui)
                    }
                }
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                if newValue {
                    requestNotificationPermission()
                } else {
                    #if canImport(UIKit)
                    UIApplication.shared.unregisterForRemoteNotifications()
                    #endif
                }
            }
            .onAppear {
                if let ui = (!avatarData.isEmpty ? UIImage(data: avatarData) : nil) {
                    profileImage = Image(uiImage: ui)
                }
            }
            .overlay(alignment: .center) {
                if isRefreshing {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                        VStack(spacing: 10) {
                            ProgressView("Aggiornamento in corso…")
                            Text("Sincronizzo i dati dal server").font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
                    .frame(width: 260, height: 120)
                } else if didJustRefresh {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Dati aggiornati")
                        }
                        .font(.headline)
                        .padding(12)
                    }
                    .frame(width: 200, height: 60)
                    .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - Appearance Settings View


struct AppearanceSettingsView: View {
    @AppStorage("laba.theme") private var themePreference: String = "system"
    @AppStorage("laba.accent") private var accentChoice: String = "system"

    var body: some View {
        List {
            Section("Tema") {
                appearanceRow(title: "Sistema", tag: "system", icon: "gearshape.fill")
                appearanceRow(title: "Chiaro", tag: "light", icon: "sun.max.fill")
                appearanceRow(title: "Scuro", tag: "dark", icon: "moon.fill")
            }
            Section("Colore accento") {
                ForEach([
                    ("system","Sistema"),
                    ("peach","Pesca"),
                    ("lavender","Lavanda"),
                    ("mint","Menta"),
                    ("sand","Sabbia"),
                    ("sky","Cielo")
                ], id: \.0) { key, label in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AccentPalette.previewColor(named: key))
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                        Text(label)
                        Spacer()
                        if accentChoice == key { Image(systemName: "checkmark").foregroundStyle(.secondary) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        accentChoice = key
                        UserDefaults.standard.set(key, forKey: "laba.accent")
                    }
                }
            }

            Section("Colori speciali") {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AccentPalette.previewColor(named: "brand"))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                    Text("Blu LABA")
                    Spacer()
                    if accentChoice == "brand" { Image(systemName: "checkmark").foregroundStyle(.secondary) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    accentChoice = "brand"
                    UserDefaults.standard.set("brand", forKey: "laba.accent")
                }
            }
        }
        .navigationTitle("Aspetto")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if accentChoice == "seafoam" { // migrazione dal vecchio turchese
                accentChoice = "system"
                UserDefaults.standard.set("system", forKey: "laba.accent")
            }
        }
    }

    @ViewBuilder
    private func appearanceRow(title: String, tag: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            if themePreference == tag { Image(systemName: "checkmark").foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            themePreference = tag
            UserDefaults.standard.set(tag, forKey: "laba.theme")
        }
    }
}

fileprivate struct RowPulseGlow: View {
    let active: Bool
    let color: Color
    let corner: CGFloat
    let minOpacity: Double
    let maxOpacity: Double
    @State private var on: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color.clear)
            .shadow(color: color.opacity(active ? (on ? maxOpacity : minOpacity) : 0.0),
                    radius: active ? (on ? 12 : 6) : 0,
                    x: 0, y: 0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    on.toggle()
                }
            }
    }
}

struct MaterialiView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "hourglass").font(.largeTitle).foregroundStyle(.secondary)
                    Text("In lavorazione...").font(.headline)
                    Text("Presto vedrai aggiornamenti in questa sezione.").font(.footnote).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } header: {
                Text("Materiali")
            }
        }
        .navigationTitle("Materiali")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DocumentiView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "hourglass").font(.largeTitle).foregroundStyle(.secondary)
                    Text("In lavorazione...").font(.headline)
                    Text("Presto vedrai aggiornamenti in questa sezione.").font(.footnote).foregroundStyle(.secondary)
                }
            } header: {
                Text("Documenti")
            }
        }
        .navigationTitle("Documenti")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct RegolamentiView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "hourglass").font(.largeTitle).foregroundStyle(.secondary)
                    Text("In lavorazione...").font(.headline)
                    Text("Presto vedrai aggiornamenti in questa sezione.").font(.footnote).foregroundStyle(.secondary)
                }            } header: {
                Text("Regolamenti")
            }
        }
        .navigationTitle("Regolamenti")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - FAQ

struct FAQView: View {
    @EnvironmentObject var vm: SessionVM

    // Modelli
    struct FAQItem: Identifiable, Hashable { let id = UUID(); let q: String; let a: String }
    struct FAQCategory: Identifiable, Hashable { let id = UUID(); let title: String; let items: [FAQItem] }

    // TUTTE le categorie/Q&A (versione completa)
    private let cats: [FAQCategory] = [

        // 1) Domande comuni
        FAQCategory(title: "Domande comuni", items: [
            FAQItem(q: "Dove sono le sedi LABA Firenze?",
                    a: "Fashion Design: Via de' Vecchietti 6. Sede principale e altri indirizzi: Piazza di Badia a Ripoli 1/A."),
            FAQItem(q: "Come ricevo comunicazioni ufficiali?",
                    a: "Alla mail @labafirenze.com e come avvisi/notifiche in app."),
            FAQItem(q: "A chi scrivo per informazioni generali?",
                    a: "Alla Segreteria Didattica (info@laba.biz) indicando nome, cognome e matricola."),
            FAQItem(q: "Cos'è la media di carriera nell'app?",
                    a: "Media matematica sui CFA degli esami con voto; idoneità/attività senza voto non influiscono.")
        ]),

        // 2) Permessi e fuori corso
        FAQCategory(title: "Permessi e fuori corso", items: [
            FAQItem(q: "Posso chiedere un permesso prolungato?",
                    a: "Sì. Invia richiesta formale alla segreteria con documentazione. La Direzione valuta e risponde via mail."),
            FAQItem(q: "Quante assenze sono consentite?",
                    a: "Dipende dal corso. Consulta il programma o il docente."),
            FAQItem(q: "Sono fuori corso: cosa cambia?",
                    a: "Rimani iscritto finché completi esami/tesi; potrebbero valere quote e limiti. Verifica con la segreteria."),
            FAQItem(q: "Posso sostenere esami da fuoricorso?",
                    a: "Sì, nel rispetto di propedeuticità e calendario. Prenota gli appelli quando disponibili.")
        ]),

        // 3) Agevolazioni
        FAQCategory(title: "Agevolazioni", items: [
            FAQItem(q: "Esistono riduzioni o esoneri?",
                    a: "Eventuali agevolazioni (ISEE, merito, esigenze specifiche) sono pubblicate in bandi/regolamenti."),
            FAQItem(q: "Supporto per DSA/disabilità?",
                    a: "Sì. Scrivi alla segreteria allegando certificazione per attivare misure compensative/dispensive."),
            FAQItem(q: "Borse di studio?",
                    a: "Verifica i bandi regionali/nazionali e gli avvisi LABA pubblicati nei canali ufficiali.")
        ]),

        // 4) Iscrizione ad esami e seminari
        FAQCategory(title: "Iscrizione ad esami e seminari", items: [
            FAQItem(q: "Come mi iscrivo a un esame?",
                    a: "In app: Esami → corso → Prenota, quando l’appello è aperto."),
            FAQItem(q: "Perché non vedo ‘Prenota’?",
                    a: "Finestra non aperta, propedeuticità non superata o posizione amministrativa da regolarizzare."),
            FAQItem(q: "Posso annullare una prenotazione?",
                    a: "Sì se la finestra è aperta: apri la scheda e tocca Annulla; altrimenti contatta la segreteria."),
            FAQItem(q: "Come mi iscrivo a un seminario/tirocinio?",
                    a: "In app: Seminari → dettaglio → Prenota. Controlla requisiti, posti e CFA."),
            FAQItem(q: "Quando aprono gli appelli?",
                    a: "Le finestre sono comunicate da segreteria e compaiono in app quando attive."),
            FAQItem(q: "Serve aver superato esami propedeutici?",
                    a: "Sì. Senza i propedeutici richiesti non potrai prenotare l’esame successivo.")
        ]),

        // 5) Regolamenti e carriera
        FAQCategory(title: "Regolamenti e carriera", items: [
            FAQItem(q: "Cosa sono i CFA?",
                    a: "Crediti Formativi Accademici: misurano il carico di lavoro delle attività didattiche."),
            FAQItem(q: "Come vengono registrati i CFA dei seminari?",
                    a: "Dopo verifica presenze/prova, il docente/ufficio verbalizza e i crediti appaiono nel libretto."),
            FAQItem(q: "Cos'è una propedeuticità?",
                    a: "Vincolo: devi superare l’esame A per poterti iscrivere all’esame B."),
            FAQItem(q: "Posso sostenere esami di anno superiore?",
                    a: "Sì se rispetti propedeuticità e le regole del tuo indirizzo."),
            FAQItem(q: "Dove trovo i regolamenti?",
                    a: "In Profilo → Regolamenti e sul sito istituzionale LABA.")
        ]),

        // 6) Tesi e laurea
        FAQCategory(title: "Tesi e laurea", items: [
            FAQItem(q: "Cos'è la tesi di laurea?",
                    a: "Progetto/ricerca conclusiva con relatore, secondo linee guida su struttura e formati."),
            FAQItem(q: "Come scelgo relatore e tema?",
                    a: "Contatta i docenti dell’indirizzo con una proposta; la conferma passa dal coordinamento."),
            FAQItem(q: "Quando e come consegno i file?",
                    a: "Le scadenze e i formati sono nelle linee guida tesi. Rispetta nomi file e dimensioni."),
            FAQItem(q: "Sessioni di laurea: quando?",
                    a: "Le date sono comunicate dalla segreteria e pubblicate nei canali ufficiali."),
            FAQItem(q: "Come ritiro la pergamena?",
                    a: "La segreteria avvisa quando pronta. Ritiro su appuntamento con documento o delega."),
            FAQItem(q: "Cosa porto alla seduta?",
                    a: "Il materiale previsto dal regolamento tesi (presentazione, book, elaborati) e documento d’identità.")
        ]),

        // 7) Uso dell'app
        FAQCategory(title: "Uso dell'app", items: [
            FAQItem(q: "Non riesco ad accedere: cosa controllo?",
                    a: "Formato mail (nome.cognome@labafirenze.com), password, blocco maiuscole, connessione."),
            FAQItem(q: "Come cambio tema o colore accento?",
                    a: "Profilo → Aspetto: sistema/chiaro/scuro e palette colori."),
            FAQItem(q: "Perché non ricevo notifiche?",
                    a: "Verifica permessi iOS e la sezione Notifiche in app; le mail istituzionali arrivano comunque."),
            FAQItem(q: "Dove vedo media e CFA totali?",
                    a: "In Home nel riquadro Riepilogo e nel widget iOS."),
            FAQItem(q: "Posso contattare un docente dall'app?",
                    a: "Sì: swipe a sinistra sul corso o nel dettaglio → ‘Invia mail al docente’."),
            FAQItem(q: "Posso caricare una foto profilo?",
                    a: "Sì dall’avatar in Profilo; resta locale e non sostituisce la foto ufficiale.")
        ]),

        // 8) Software e laboratori
        FAQCategory(title: "Software e laboratori", items: [
            FAQItem(q: "Quali software si usano?",
                    a: "Suite Adobe, 3D (Cinema 4D, Rhinoceros) e strumenti specifici per indirizzo."),
            FAQItem(q: "Come attivo licenze educational?",
                    a: "Segui le istruzioni inviate alla mail istituzionale; licenze con scadenza annuale."),
            FAQItem(q: "Posso usare i laboratori fuori orario?",
                    a: "Orari e regole di prenotazione sono comunicati dall’Accademia."),
            FAQItem(q: "Problema tecnico in aula/lab: chi contatto?",
                    a: "Avvisa docente e reparto IT, indicando corso, aula e postazione."),
            FAQItem(q: "Uso software a casa: requisiti minimi?",
                    a: "Dipende dal software; consulta le specifiche fornite dal docente o nelle guide LABA.")
        ]),

        // 9) Orari e calendario
        FAQCategory(title: "Orari e calendario", items: [
            FAQItem(q: "Quando esce l'orario provvisorio?",
                    a: "All’inizio del semestre; variazioni via mail/avvisi."),
            FAQItem(q: "Dove vedo il calendario appelli?",
                    a: "In app (Esami) e nelle comunicazioni ufficiali quando attivati."),
            FAQItem(q: "Ci sono chiusure straordinarie?",
                    a: "Eventuali chiusure sono annunciate via mail e in app (Avvisi/Notifiche)."),
            FAQItem(q: "Come vengo informato sugli eventi?",
                    a: "Tramite sito, social e comunicazioni interne/seminari in app.")
        ]),

        // 10) Coordinatori e referenti
        FAQCategory(title: "Coordinatori e referenti", items: [
            FAQItem(q: "Chi è il coordinatore del mio indirizzo?",
                    a: "È indicato nell’organigramma sul sito; contatti reperibili anche tramite la segreteria."),
            FAQItem(q: "Come contatto il coordinamento?",
                    a: "Scrivi alla segreteria che indirizzerà la richiesta al referente corretto."),
            FAQItem(q: "A chi segnalo richieste didattiche?",
                    a: "Al docente del corso o al coordinatore di indirizzo, a seconda del tema.")
        ]),

        // 11) Pagamenti e posizione
        FAQCategory(title: "Pagamenti e posizione", items: [
            FAQItem(q: "Cosa significa ‘pagamenti non in regola’?",
                    a: "Verifica la posizione amministrativa; alcune funzioni (prenotazioni) possono essere bloccate."),
            FAQItem(q: "Posso sostenere esami con pagamenti in sospeso?",
                    a: "Di norma no, finché non regolarizzi."),
            FAQItem(q: "Dove trovo le scadenze di pagamento?",
                    a: "Nel contratto/iscrizione e nelle comunicazioni della segreteria."),
            FAQItem(q: "Ricevute e certificazioni?",
                    a: "Richiedile alla segreteria amministrativa indicando matricola e periodo d’interesse.")
        ]),

        // 12) Privacy e sicurezza
        FAQCategory(title: "Privacy e sicurezza", items: [
            FAQItem(q: "L'app salva dati sensibili?",
                    a: "Solo impostazioni locali (tema, accento, avatar). I dati accademici passano per servizi autenticati."),
            FAQItem(q: "Come gestite i miei dati?",
                    a: "Secondo privacy policy LABA. Consulta Profilo → Privacy Policy."),
            FAQItem(q: "Posso cancellare i dati locali dell'app?",
                    a: "Sì: effettua il logout e rimuovi l’app; alla nuova installazione ripartirai da zero.")
        ])
    ]

    @State private var selected: String = "Tutte"
    private var titles: [String] { ["Tutte"] + cats.map { $0.title } }
    private var categoriesToShow: [FAQCategory] {
        selected == "Tutte" ? cats : cats.filter { $0.title == selected }
    }

    var body: some View {
        List {
            ForEach(categoriesToShow) { c in
                Section {
                    ForEach(c.items) { it in
                        DisclosureGroup(it.q) {
                            Text(it.a)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(c.title)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Puoi usare direttamente un Picker dentro al Menu
                    Picker("Categoria", selection: $selected) {
                        ForEach(titles, id: \.self) { Text($0).tag($0) }
                    }
                } label: {
                    // Etichetta con categoria corrente o “Tutte”
                    Label(selected == "Tutte" ? "Categoria" : selected,
                          systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}


// MARK: - Calcolo Media (Ingresso Tesi)
struct CalcolaMediaView: View {
    @EnvironmentObject var vm: SessionVM
    @State private var inputAvg: String = ""
    @State private var rawScaled: Double? = nil
    @State private var officialScaled: Int? = nil

    private func suggestedAverageFromApp() -> Double? {
        // Media aritmetica sui soli voti numerici, escludendo Attività/Tesi
        let numeric: [Int] = vm.esami.compactMap { e in
            let lowered = e.corso.lowercased()
            if lowered.contains("attivit") || lowered.contains("tesi") { return nil }
            guard let v = e.voto, !v.isEmpty else { return nil }
            let cleaned = v.replacingOccurrences(of: " e lode", with: "")
            let first = cleaned.components(separatedBy: "/").first ?? cleaned
            return Int(first.trimmingCharacters(in: .whitespaces))
        }
        guard !numeric.isEmpty else { return nil }
        let sum = numeric.reduce(0, +)
        return Double(sum) / Double(numeric.count)
    }

    private func computeScaledTo110(from avg30: Double) -> (raw: Double, official: Int) {
        // Scala /30 → /110
        let x = avg30 * (110.0 / 30.0)
        let frac = x - floor(x)
        // Regola richiesta: se la parte decimale supera 0,50 → arrotonda per eccesso, altrimenti per difetto
        let official: Int = (frac > 0.50) ? Int(ceil(x)) : Int(floor(x))
        return (x, official)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Inserisci media su 30 (es. 26,8)", text: $inputAvg)
                            .keyboardType(.decimalPad)
                        Button("Calcola") {
                            let cleaned = inputAvg.replacingOccurrences(of: ",", with: ".")
                            if let v = Double(cleaned) {
                                let out = computeScaledTo110(from: v)
                                rawScaled = out.raw
                                officialScaled = out.official
                            } else {
                                rawScaled = nil
                                officialScaled = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)

                    }

                    if let raw = rawScaled, let off = officialScaled {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Ti presenterai con")
                                Spacer()
                                Text("\(off)/110").font(.title2.weight(.semibold))
                            }
                            Text("Se l'eccedenza decimale del voto supera lo 0.50, si approssima per eccesso.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
            } header: {
                Text("Con quanto mi presenterò?")
            }

            Section {
                if let s = suggestedAverageFromApp() {
                    Button {
                        inputAvg = String(format: "%.1f", s)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Utilizza la media proposta")
                                Spacer()
                                HStack(spacing: 6) {
                                    Text(String(format: "%.1f", s))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle().fill(Color.labaAccent)
                                        )
                                }
                            }
                            Text("La media proposta dall'applicazione LABA tiene conto dei valori ufficiali, con un margine di errore minimo.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Non è disponibile una media proposta. Inseriscila manualmente.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill.questionmark")
                        Text("Come funziona il calcolo?")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    Group {
                        Text("1) Vengono considerati tutti gli esami con voto numerico. “30 e lode” conta come 30/30.")
                        Text("2) Idoneità, attività integrative e tirocini non entrano nel calcolo.")
                        Text("3) Come viene calcolata la media generale: sommiamo i voti di tutti gli esami con voto registrato previsti dal tuo piano di studi e dividiamo per il numero di questi esami. (Gli esami senza voto non vengono conteggiati.)")
                        Text("4) Da qui si ottiene il voto d’ingresso in tesi: convertiamo la media in /110 con media × 110 ÷ 30.")
                        Text("5) Arrotondamento: se la parte decimale > 0,50 arrotondiamo in su, altrimenti in giù.")
                        Text("Esempio: 28,8 × 110 ÷ 30 = 105,69 → ti presenterai con 106/110.")
                            .monospaced()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    Text("Nota: per accedere alla tesi servono **tutti i CFA** e **tutti gli esami** completati; questo requisito non modifica la media.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Suggerimenti")
            }
        }
        .navigationTitle("Voto d'Ingresso")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct HomeView: View {
    @EnvironmentObject var vm: SessionVM
    // Kick a one-time refresh to ensure announcements are fetched (old Home did this explicitly)
    @State private var didKickAnnouncementsFetch = false

    // MARK: - Helpers (nuove regole LABA)
    private func isAttivitaOTesi(_ e: Esame) -> Bool {
        let t = e.corso.lowercased()
        return t.contains("attivit") || t.contains("tesi")
    }

    private func isIdoneita(_ e: Esame) -> Bool {
        let v = (e.voto ?? "").lowercased()
        return v.contains("idoneo") || v.contains("idonea") || v.contains("idone")
    }

    private func hasNumericVote(_ e: Esame) -> Bool {
        let v = e.voto ?? ""
        return v.range(of: #"^\s*\d+\s*/\s*\d+"#, options: .regularExpression) != nil
    }

    // Helpers per distinguere Attività integrative e Tesi
    private func isAttivitaIntegrativa(_ e: Esame) -> Bool {
        // Esempio nei dati: "ATTIVITÀ A SCELTA (Workshop/Seminari/Stage)"
        return e.corso.lowercased().contains("attivit")
    }

    private func isTesiFinale(_ e: Esame) -> Bool {
        return e.corso.lowercased().contains("tesi")
    }

    /// Conteggio esami totali: conta tutti i corsi che non sono Attività/Tesi,
    /// indipendentemente dal fatto che abbiano già un voto.
    private func isCountableForTotals(_ e: Esame) -> Bool {
        // Conta nel TOTALE tutti i corsi che non sono Attività/Tesi,
        // indipendentemente dal fatto che abbiano già un voto.
        return !isAttivitaOTesi(e)
    }

    /// Esami conteggiati (totali) = numerici + idoneità; esclusi Attività/Tesi
    private var validExams: [Esame] { vm.esami.filter { isCountableForTotals($0) } }

    /// Sostenuti ai fini del conteggio (numerici O idoneità con voto presente)
    private var passedExamsCount: Int {
        validExams.filter { !(($0.voto ?? "").isEmpty) }.count
    }

    /// Totale esami (numerici + idoneità), esclusi Attività/Tesi
    private var totalExamsCount: Int { validExams.count }
    private var missingExamsCount: Int { max(totalExamsCount - passedExamsCount, 0) }

    /// Stato: utente laureato
    private var isGraduated: Bool {
        (vm.status ?? "").lowercased().contains("laureat")
    }

    /// CFA: il TARGET è la somma di TUTTI i CFA (esami, idoneità, attività, tesi)
    private var cfaTarget: Int {
        vm.esami.reduce(0) { $0 + (Int($1.cfa ?? "") ?? 0) }
    }
    /// CFA guadagnati secondo regole LABA (esami + max 10 Attività integrative + Tesi)
    private var cfaEarned: Int {
        // Completamento = ha un voto (numerico o idoneità) oppure una data di sostenimento
        func isCompleted(_ e: Esame) -> Bool { !(e.voto ?? "").isEmpty || (e.sostenutoIl != nil) }

        // 1) Esami (escludi Attività e Tesi)
        let examsEarned = vm.esami.reduce(0) { acc, e in
            guard !isAttivitaIntegrativa(e), !isTesiFinale(e) else { return acc }
            guard isCompleted(e), let c = Int(e.cfa ?? "") else { return acc }
            return acc + c
        }

        // 2) Attività integrative (Seminari/Workshop/Tirocini) → max 10 CFA totali
        let attivita = vm.esami.filter { isAttivitaIntegrativa($0) }
        let declaredActivitiesCFA = attivita.compactMap { Int($0.cfa ?? "") }.reduce(0, +) // di solito 10
        let anyActivityCompleted = attivita.contains { isCompleted($0) }
        let activitiesEarned: Int = {
            if isGraduated { return 10 } // laureato: consideriamo acquisiti i 10 CFA totali di Attività
            return anyActivityCompleted ? min(10, declaredActivitiesCFA) : 0
        }()

        // 3) Tesi finale
        let thesis = vm.esami.filter { isTesiFinale($0) }
        let thesisCFA = thesis.compactMap { Int($0.cfa ?? "") }.first ?? 0
        let thesisCompleted = thesis.contains { isCompleted($0) }
        let thesisEarned = (isGraduated || thesisCompleted) ? thesisCFA : 0

        return examsEarned + activitiesEarned + thesisEarned
    }
    private var cfaPercent: Double {
        let tot = cfaTarget
        guard tot > 0 else { return 0 }
        return Double(cfaEarned) / Double(tot)
    }

    /// Avanzamento per ANNO CORRENTE: (anno, sostenuti, totali, percentuale)
    private var yearProgress: (year: Int, passed: Int, total: Int, percent: Double)? {
        guard let y = vm.currentYear else { return nil }
        let examsYear = vm.esami.filter { !isAttivitaOTesi($0) && $0.anno == y }
        let total = examsYear.count
        let passed = examsYear.filter { !(($0.voto ?? "").isEmpty) }.count
        let percent = total > 0 ? Double(passed) / Double(total) : 0
        return (y, passed, total, percent)
    }

    // Statistiche per anno: restituisce sostenuti, totali, mancanti e percentuale di completamento (1 - missing/total)
    private func statsForYear(_ y: Int) -> (passed: Int, total: Int, missing: Int, percent: Double) {
        let exams = vm.esami.filter { !isAttivitaOTesi($0) && $0.anno == y }
        let total = exams.count
        let passed = exams.filter { !(($0.voto ?? "").isEmpty) }.count
        let missing = max(0, total - passed)
        let percent = total > 0 ? 1.0 - (Double(missing) / Double(total)) : 0
        return (passed, total, missing, percent)
    }

    /// Media aritmetica sui soli voti numerici (0..30). Nil se assente
    private var careerAverageValue: Double? {
        let numeric = vm.esami.filter { !isAttivitaOTesi($0) && hasNumericVote($0) }
        let marks: [Int] = numeric.compactMap { e in
            let raw = (e.voto ?? "").replacingOccurrences(of: " e lode", with: "")
            return Int(raw.components(separatedBy: "/").first ?? "")
        }
        guard !marks.isEmpty else { return nil }
        return Double(marks.reduce(0, +)) / Double(marks.count)
    }

    // Schiarisce leggermente il colore d'accento per la pill in Hero
    private func lighterAccent(by delta: CGFloat = 0.15) -> Color {
#if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let ui = UIColor(.labaAccent)
        _ = ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        // aumenta la luminosità e riduce di poco la saturazione per migliorare il contrasto del testo bianco
        let nb = min(1.0, b + delta)
        let ns = max(0.0, s - (delta * 0.35))
        let out = UIColor(hue: h, saturation: ns, brightness: nb, alpha: a)
        return Color(out)
#else
        return Color.labaAccent.opacity(0.90)
#endif
    }

    // Calcola un outline accent che contrasta con il fill e con l'hero
    private func outlineAccent(from base: Color) -> Color {
#if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let ui = UIColor(base)
        // se non riesco a leggere HSB, ripiego su labaAccent più scuro
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return Color.labaAccent.opacity(0.95)
        }
        // Outline più saturo e più scuro per staccare sia dal fill che dal gradient hero
        let ns = min(1.0, s + 0.18)
        let nb = max(0.0, b - 0.15)
        return Color(UIColor(hue: h, saturation: ns, brightness: nb, alpha: a))
#else
        return Color.labaAccent.opacity(0.95)
#endif
    }

    @ViewBuilder
    private var statusPillRow: some View {
        let isLaureato = vm.status?.lowercased().contains("laureat") ?? false
        if isLaureato {
            HStack(spacing: 6) {
                Pill(text: vm.graduatedWord(), kind: .status)
                    .foregroundStyle(Color.white) // testo bianco nella pillola
                    .background(
                        Capsule().fill(lighterAccent()) // fondo accent leggermente più chiaro
                    )
                    .overlay(
                        Capsule().stroke(outlineAccent(from: lighterAccent()), lineWidth: 1) // outline accent
                    )
                    .compositingGroup()

                Text("ma perché usi ancora l'app?")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.95))

                Spacer()
            }
        } else if let year = vm.currentYear {
            HStack(spacing: 8) {
                Pill(text: italianOrdinalYear(year), kind: .year)
                    .foregroundStyle(Color.white) // testo bianco nella pillola
                    .background(
                        Capsule().fill(lighterAccent()) // fondo accent leggermente più chiaro
                    )
                    .overlay(
                        Capsule().stroke(outlineAccent(from: lighterAccent()), lineWidth: 1) // outline accent
                    )
                    .compositingGroup()

                let disp = courseDisplayInfo(from: vm.pianoStudi)
                Text((disp?.name ?? "") + ((disp?.aa ?? "").isEmpty ? "" : " • \(disp!.aa)"))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.95)) // corso + A.A. sempre bianchi in HERO
                Spacer()
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // HERO
                    ZStack(alignment: .leading) {
                        let heroPair = heroGradient(from: .labaAccent)
                        LinearGradient(
                            gradient: Gradient(colors: [heroPair.0, heroPair.1]),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .frame(height: 140)
                        .cornerRadius(22)
                        .shadow(color: Color.labaAccent.opacity(0.18), radius: 10, x: 0, y: 5)
                        .overlay(
                            ConfettiOverlay()
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ciao, \(vm.displayName ?? "")! 👋")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            statusPillRow
                        }
                        .padding(.horizontal, 26)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // KPI – testo nero; glow su "mancanti"
                    HStack(spacing: 16) {
                        kpiCard(title: "Esami\nsostenuti",
                                value: "\(passedExamsCount)",
                                emphasizeGlow: false)
                        kpiCard(title: "Esami\nmancanti",
                                value: "\(missingExamsCount)",
                                emphasizeGlow: true)
                        kpiCard(title: "CFA \nacquisiti",
                                value: "\(cfaEarned)",
                                emphasizeGlow: false)
                    }
                    .padding(.horizontal)

                    // Riepilogo anno corrente + Media totale
                    VStack(alignment: .leading, spacing: 10) {
                        // Avanzamento per anno (1º, 2º, 3º) — layout in 3 colonne
                        Text("Come stai andando?").font(.subheadline.weight(.bold))
                        HStack(spacing: 12) {
                            ForEach([1, 2, 3], id: \.self) { y in
                                let s = statsForYear(y)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Esami \(italianOrdinalYear(y))")
                                        .font(.footnote.weight(.semibold))
                                    ProgressView(value: s.total > 0 ? s.percent : 0)
                                        .tint(.labaAccent)
                                        .frame(height: 10)
                                        .clipShape(Capsule())
                                    Text(s.total > 0 ? "mancanti \(s.missing)" : "—")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Divider().padding(.vertical, 4)

                        // Media totale
                        HStack {
                            Text("La tua media").font(.subheadline.weight(.bold))
                            Spacer()
                            Text(careerAverageValue != nil ? String(format: "%.1f/30", careerAverageValue!) : "—")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        ProgressView(value: careerAverageValue != nil ? min(1.0, max(0.0, (careerAverageValue!/30.0))) : 0)
                            .tint(.labaAccent)
                            .frame(height: 15)
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                    .shadow(color: Color.labaAccent.opacity(0.08), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)

                    // AVVISI – mostra le prime 2 e apre la lista completa (usa API via vm.notifications)
                    NavigationLink {
                        NotificheView().environmentObject(vm)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "megaphone.fill")
                                Text("Avvisi").font(.headline)
                                Spacer()
                                if !vm.notifications.isEmpty { Text("Vedi tutti").font(.footnote).foregroundStyle(.secondary) }
                            }
                            .foregroundStyle(.primary)

                            if vm.notifications.isEmpty {
                                Text("Nessun avviso disponibile.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(vm.notifications.prefix(2)), id: \.id) { n in
                                        Text((n.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? n.title! : n.message))
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                        .shadow(color: Color.labaAccent.opacity(0.08), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // PROSSIME LEZIONI – full width, icona sinistra
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                            Text("Prossime lezioni").font(.headline)
                        }
                        .foregroundStyle(.primary)
                        Text("Nessuna lezione imminente.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                    .shadow(color: Color.labaAccent.opacity(0.08), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)

                    // PER TE — Scorciatoie
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Per te").font(.headline)
                            Spacer()
                        }
                        VStack(spacing: 0) {
                            // Row 1 — attivo
                            NavigationLink {
                                CalcolaMediaView().environmentObject(vm)
                            } label: {
                                perTeSystemRow(icon: "plusminus.circle.fill", title: "Voto d’ingresso")
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 44)

                            // Row 2 — placeholder disabilitato
                            perTeSystemRow(icon: "camera.circle.fill", title: "Strumentazione", enabled: false)

                            Divider().padding(.leading, 44)

                            // Row 3 — placeholder disabilitato
                            perTeSystemRow(icon: "inset.filled.rectangle.and.person.filled.circle.fill", title: "Aule", enabled: false)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                    .shadow(color: Color.labaAccent.opacity(0.08), radius: 6, x: 0, y: 2)
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.top, 6)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(" ")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.automatic, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            if !didKickAnnouncementsFetch {
                didKickAnnouncementsFetch = true
                await vm.loadNotifications()
            }
        }
    }

    // MARK: - Hero Gradient Helper
    private func heroGradient(from accent: Color) -> (Color, Color) {
#if canImport(UIKit)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let ui = UIColor(accent)
        _ = ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let left = UIColor(hue: h,
                           saturation: min(1.0, s + 0.05),
                           brightness: max(0.60, min(0.95, b - 0.02)),
                           alpha: a)
        let right = UIColor(hue: h,
                            saturation: max(0.45, s - 0.28),
                            brightness: min(0.88, b + 0.18),
                            alpha: a)
        return (Color(left), Color(right))
#else
        return (accent.opacity(0.9), accent.opacity(0.7))
#endif
    }

    // MARK: - Subviews
    @ViewBuilder
    private func kpiCard(title: String, value: String, emphasizeGlow: Bool) -> some View {
        let esamiMancanti = missingExamsCount
        let isComplete = esamiMancanti == 0
        let completedFocus = emphasizeGlow && isComplete && totalExamsCount > 0

        // Opacità interna in funzione degli esami mancanti
        let opacity: Double = {
            let m = esamiMancanti
            if m <= 0 { return 0.06 }
            switch m {
            case 1: return 0.50
            case 2: return 0.44
            case 3: return 0.38
            case 4: return 0.31
            case 5: return 0.24
            default: return 0.06
            }
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(completedFocus ? Color.labaAccent : Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    Group {
                        if !completedFocus {
                            AnimatedGradientBackground(base: .labaAccent, esamiMancanti: esamiMancanti)
                                .opacity(emphasizeGlow ? opacity : 0.06)
                                .mask(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke((completedFocus ? Color.white.opacity(0.18) : Color.primary.opacity(0.06)), lineWidth: 1)
                )

            // Content
            VStack(spacing: 6) {
                if completedFocus {
                    RibbonCheckIcon(size: 28, tint: .white)
                    Text("Hai sostenuto tutti gli esami!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.95))
                } else {
                    Text(value)
                        .font(.title2).bold()
                        .foregroundColor(.primary)
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
            .padding(6)
            .padding(.vertical, 3)
        }
        .background(
            TightGlow(active: completedFocus, color: .labaAccent, corner: 14)
        )
    }
    
    fileprivate struct PulseGlow: View {
        let active: Bool
        let color: Color
        let corner: CGFloat
        @State private var phase: Bool = false

        var body: some View {
            RoundedRectangle(cornerRadius: corner)
                .stroke(color.opacity(active ? 0.001 : 0.0), lineWidth: 1) // micro-stroke per abilitare lo shadow
                .shadow(color: color.opacity(active ? (phase ? 0.35 : 0.18) : 0.0),
                        radius: active ? (phase ? 10 : 5) : 0,
                        x: 0, y: 0)
                .allowsHitTesting(false)
                .onAppear {
                    guard active else { return }
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        phase.toggle()
                    }
                }
                .onChange(of: active) { _, newVal in
                    if newVal {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            phase = true
                        }
                    } else {
                        phase = false
                    }
                }
        }
    }

    // Static glow effect for completed KPI
    fileprivate struct StaticGlow: View {
        let active: Bool
        let color: Color
        let corner: CGFloat
        let opacity: Double
        let radius: CGFloat

        var body: some View {
            RoundedRectangle(cornerRadius: corner)
                .fill(color.opacity(active ? 0.001 : 0.0)) // micro-fill per permettere allo shadow di renderizzare
                .shadow(color: color.opacity(active ? opacity : 0.0),
                        radius: active ? radius : 0,
                        x: 0, y: 0)
                .allowsHitTesting(false)
        }
    }

    // Glow additivo stile "Apple Intelligence": leggero, fuori bordo, con respiro
    fileprivate struct AIGlow: View {
        let active: Bool
        let color: Color
        let corner: CGFloat
        @State private var phase: Bool = false

        var body: some View {
            ZStack {
                // Bloom esterno morbido (additivo)
                RoundedRectangle(cornerRadius: corner)
                    .fill(color.opacity(active ? (phase ? 0.18 : 0.10) : 0.0))
                    .blur(radius: active ? (phase ? 18 : 10) : 0)
                    .scaleEffect(active ? (phase ? 1.04 : 1.02) : 1)
                    .blendMode(.screen)
                    .padding(-12) // estendi oltre i bordi per far "uscire" il glow
                    .allowsHitTesting(false)
                    .compositingGroup()
            }
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    phase.toggle()
                }
            }
            .onChange(of: active) { _, newVal in
                if newVal {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        phase = true
                    }
                } else {
                    phase = false
                }
            }
        }
    }

    // Ribbon/premio con checkmark (sempre disponibile, iOS 15+)
    fileprivate struct RibbonCheckIcon: View {
        var size: CGFloat = 28
        var tint: Color = .labaAccent
        var body: some View {
            ZStack {
                Image(systemName: "rosette")
                    .font(.system(size: size))
                    .foregroundColor(tint)
            }
            .accessibilityLabel("Tutti gli esami sono stati sostenuti")
        }
    }
    // Glow molto aderente ai bordi (tighter edge glow) con effetto pulse di opacità
    fileprivate struct TightGlow: View {
        let active: Bool
        let color: Color
        let corner: CGFloat
        @State private var phase: Bool = false

        var body: some View {
            ZStack {
                // Anello molto vicino al bordo esterno (softened version)
                RoundedRectangle(cornerRadius: corner)
                    .stroke(color.opacity(active ? 0.48 : 0.0), lineWidth: 5)
                    .blur(radius: active ? 6 : 0)
                    .padding(-4)
                    .allowsHitTesting(false)
                // Bordo interno luminoso sottile (più definito ma ancora morbido)
                RoundedRectangle(cornerRadius: corner)
                    .stroke(color.opacity(active ? 0.42 : 0.0), lineWidth: 2.5)
                    .blur(radius: active ? 1.2 : 0)
                    .allowsHitTesting(false)
            }
            // Pulse dall'aspetto attuale → scomparsa → aspetto attuale (loop)
            .opacity(active ? (phase ? 1.0 : 0.0) : 0.0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    phase.toggle()
                }
            }
            .onChange(of: active) { _, newVal in
                if newVal {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        phase = true
                    }
                } else {
                    phase = false
                }
            }
        }
    }

    @ViewBuilder
    private func perTeRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Text(icon).font(.title2)
            Text(text).font(.headline)
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.labaAccent.opacity(0.13))
                .shadow(color: Color.labaAccent.opacity(0.11), radius: 3, x: 0, y: 1)
        )
    }

    @ViewBuilder
    private func perTeQuickItem(icon: String, title: String, disabled: Bool = false) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.labaAccent.opacity(0.15))
                )
            Text(title)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
            if disabled {
                Text("Prossimamente")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func perTeSystemRow(icon: String, title: String, enabled: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 28, height: 28)
                .foregroundStyle(.primary)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            if enabled {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .opacity(enabled ? 1.0 : 0.55)
        .contentShape(Rectangle())
    }

    // Media ARITMETICA sui soli voti numerici (escluse idoneità, Attività, Tesi)
    private func careerAverage() -> String {
        let numeric = vm.esami.filter { !isAttivitaOTesi($0) && hasNumericVote($0) }
        let marks: [Int] = numeric.compactMap { e in
            let raw = (e.voto ?? "").replacingOccurrences(of: " e lode", with: "")
            return Int(raw.components(separatedBy: "/").first ?? "")
        }
        guard !marks.isEmpty else { return "—" }
        let avg = Double(marks.reduce(0, +)) / Double(marks.count)
        return String(format: "%.1f", avg)
    }
}

// MARK: - Confetti overlay (Canvas) ispirato a AnimatedPatternBackground
fileprivate struct ConfettiOverlay: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0/30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { _ in
                Canvas { ctx, sz in
                    // Use fixed white color for confetti overlay
                    let color: Color = .white.opacity(0.28)
                    let step: CGFloat = 28
                    let r: CGFloat = 3.0
                    drawPattern(in: &ctx, size: sz, color: color, step: step, r: r, time: CGFloat(time))
                }
            }
        }
    }

    private func drawPattern(in ctx: inout GraphicsContext, size sz: CGSize, color: Color, step: CGFloat, r: CGFloat, time: CGFloat) {
        let t = time * 0.6
        for y in stride(from: -step, through: sz.height + step, by: step) {
            for x in stride(from: -step, through: sz.width + step, by: step) {
                let seed = (x * 13 + y * 7)
                let dx = sin((x + y) / 140 + t * (1.2 + 0.17 * sin(seed))) * 9 * (0.8 + 0.3 * cos(seed))
                let dy = cos((x - y) / 120 + t * (1.3 + 0.23 * cos(seed + 99))) * 9 * (0.8 + 0.3 * sin(seed + 42))
                let rect = CGRect(x: x + dx, y: y + dy, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(color))
                ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 0.5)
            }
        }
    }
}

fileprivate struct AnimatedGradientBackground: View {
    let base: Color
    let esamiMancanti: Int

    // A few stable random seeds so the motion looks organic but deterministic per view life
    private let seeds: [CGFloat]
    private let spotsCount: Int = 6

    init(base: Color, esamiMancanti: Int) {
        self.base = base
        self.esamiMancanti = esamiMancanti
        // generate seeds once
        self.seeds = (0..<6).map { _ in .random(in: 0...1000) }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0/30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                Canvas { ctx, size in
                    let shades = makeShades(from: base, esamiMancanti: esamiMancanti)
                    let minSide = min(size.width, size.height)

                    // intensity factor grows when esamiMancanti -> 1 (0...1)
                    let maxStep = 5
                    let clamped = max(1, min(maxStep, esamiMancanti)) // 1..5
                    let factor = 1 - CGFloat(clamped - 1) / CGFloat(maxStep - 1)

                    for i in 0..<spotsCount {
                        // Pick a color from palette, cycling to ensure variety
                        let c = shades.isEmpty ? base.opacity(0.6) : shades[i % shades.count].opacity(0.75 + 0.15 * factor)

                        // Organic motion: slow Lissajous using seeds
                        let sx = seeds[i % seeds.count]
                        let sy = seeds[(i + 1) % seeds.count]
                        let px = 0.5 + 0.42 * sin( (t * 0.18) + Double(sx) / 37.0 + Double(i) )
                        let py = 0.5 + 0.42 * cos( (t * 0.15) + Double(sy) / 41.0 + Double(i) )

                        // Radius scales with view size + intensity
                        let baseR = minSide * (0.20 + 0.10 * CGFloat(i % 3))
                        let r = baseR * (0.92 + 55 * factor)

                        let center = CGPoint(x: px * size.width, y: py * size.height)
                        let grad = Gradient(colors: [
                            c.opacity(0.85),
                            c.opacity(0.35 + 0.25 * factor),
                            c.opacity(0.0)
                        ])

                        ctx.fill(
                            Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                            with: .radialGradient(
                                grad,
                                center: center,
                                startRadius: 0,
                                endRadius: r
                            )
                        )
                    }
                }
                .mask(RoundedRectangle(cornerRadius: 14)) // keep it inside the card
            }
        }
    }

    #if canImport(UIKit)
    private func makeShades(from color: Color, esamiMancanti: Int) -> [Color] {
        let ui = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return [color.opacity(0.95), color.opacity(0.75), color.opacity(0.55)]
        }

        // Intensità 0..1 (max a 1 esame, min oltre 5 esami)
        let maxStep = 5
        let clamped = max(1, min(maxStep, esamiMancanti))
        let factor = 1 - CGFloat(clamped - 1) / CGFloat(maxStep - 1) // 1→1.0, 5→0.0

        // Evita neri/grigi/bianchi: saturazione >= 0.60, brightness ∈ [0.40, 0.88]
        let satBase = max(0.60, s) + (0.22 * factor)
        let clampB: (CGFloat) -> CGFloat = { min(max($0, 0.40), 0.88) }

        let brightnessCenters: [CGFloat] = [
            clampB(b + 0.06),
            clampB(b + 0.14),
            clampB(b + 0.22)
        ]

        let satShifts: [CGFloat] = [-0.04, 0.0, 0.06, 0.12]

        var shades: [Color] = []
        for nb in brightnessCenters {
            let ns = min(max(satBase + (satShifts.randomElement() ?? 0), 0.60), 1.0)
            let c = UIColor(hue: h, saturation: ns, brightness: nb, alpha: a)
            shades.append(Color(c))
        }
        // aggiungi un tono leggermente più scuro ma mai “grigio”
        let darkerB = clampB(b - 0.10 + 0.04 * factor)
        let darkerS = min(1.0, max(0.60, satBase + 0.05))
        shades.append(Color(UIColor(hue: h, saturation: darkerS, brightness: darkerB, alpha: a)))
        return shades
    }
    #else
    private func makeShades(from color: Color, esamiMancanti: Int) -> [Color] {
        return [color.opacity(0.9), color.opacity(0.7), color.opacity(0.55)]
    }
    #endif
}

// MARK: - Accent Color Helper
extension Color {
    static var labaAccent: Color {
        let key = UserDefaults.standard.string(forKey: "laba.accent") ?? "system"
        // Mappa "system" (e legacy "seafoam") al colore d'accento di iOS
        if key == "system" || key == "seafoam" {
            return Color.accentColor
        }
        // Per il colore "brand" (Blu LABA) usa una variante dinamica più leggibile in Dark Mode
        if key == "brand" {
            #if canImport(UIKit)
            let base = UIColor(AccentPalette.color(named: "brand"))
            let dynamic = UIColor { tc in
                if tc.userInterfaceStyle == .dark {
                    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    guard base.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return base }
                    // Aumenta la leggibilità su sfondo scuro: alza la luminosità minima e riduci leggermente la saturazione
                    let nb = min(1.0, max(b, 0.86))          // almeno ~86% di brightness
                    let ns = min(1.0, max(0.60, s * 0.95))   // saturazione leggermente ridotta ma ancora "blu LABA"
                    return UIColor(hue: h, saturation: ns, brightness: nb, alpha: a)
                } else {
                    return base // Light Mode: blu LABA puro
                }
            }
            return Color(dynamic)
            #else
            return AccentPalette.color(named: "brand")
            #endif
        }
        // Altri accenti: usa la palette così com'è
        return AccentPalette.color(named: key)
    }
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var vm = SessionVM()
    @State private var selectedTab = 0
    @State private var isBooting = true
    
    @AppStorage("laba.theme") private var themePreference: String = "system"
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Group {
                if vm.isLoggedIn {
                    TabView(selection: $selectedTab) {
                        HomeView()
                            .tabItem { Label("Home", systemImage: "house.fill") }
                            .tag(0)
                            .environmentObject(vm)
                        ExamsView()
                            .tabItem { Label("Esami", systemImage: "list.bullet.rectangle.fill") }
                            .badge(vm.bookableExamsCount > 0 ? "!" : nil)
                            .tag(1)
                            .environmentObject(vm)
                        CorsiView()
                            .tabItem { Label("Corsi", systemImage: "graduationcap.fill") }
                            .tag(2)
                            .environmentObject(vm)
                        SeminariView()
                            .tabItem { Label("Seminari", systemImage: "calendar.badge.clock") }
                            .badge(vm.bookableSeminarsCount)
                            .tag(3)
                            .environmentObject(vm)
                        ProfiloView()
                            .tabItem { Label("Profilo", systemImage: "person.crop.circle.fill") }
                            .tag(4)
                            .environmentObject(vm)
                    }
                    .tint(Color.labaAccent)
                    .accentColor(Color.labaAccent)
                } else {
                    LoginView().environmentObject(vm)
                }
            }

            // Overlay: splash/loader iniziale
            if isBooting {
                AppLoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            await vm.restoreSession()
            withAnimation(.easeOut(duration: 0.25)) {
                isBooting = false
            }
        }
        .preferredColorScheme(preferredScheme(from: themePreference))
    }
}



struct ContentView_Previews: PreviewProvider { static var previews: some View { ContentView() } }
