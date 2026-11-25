import SwiftUI

enum MealContext: String, Codable, CaseIterable, Identifiable {
    case fasting, beforeMeal, afterMeal, bedtime, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting: return "صائم"
        case .beforeMeal: return "قبل الأكل"
        case .afterMeal: return "بعد الأكل"
        case .bedtime: return "قبل النوم"
        case .other: return "أخرى"
        }
    }

    var icon: String {
        switch self {
        case .fasting: return "sunrise"
        case .beforeMeal: return "fork.knife"
        case .afterMeal: return "fork.knife.circle"
        case .bedtime: return "moon.zzz"
        case .other: return "drop"
        }
    }

    static func guess(for date: Date) -> MealContext {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<10: return .fasting
        case 21..<24, 0..<4: return .bedtime
        default: return .beforeMeal
        }
    }
}

struct Reading: Identifiable, Codable, Equatable {
    var id = UUID()
    /// Always stored in mg/dL.
    var value: Double
    var date: Date
    var context: MealContext
    var note: String = ""
}

enum GlucoseUnit: String, CaseIterable, Identifiable {
    case mgdl, mmol

    var id: String { rawValue }
    var title: String { self == .mgdl ? "mg/dL" : "mmol/L" }

    func fromMg(_ mg: Double) -> Double { self == .mgdl ? mg : mg / 18.0 }
    func toMg(_ v: Double) -> Double { self == .mgdl ? v : v * 18.0 }

    func format(_ mg: Double) -> String {
        self == .mgdl ? String(format: "%.0f", mg) : String(format: "%.1f", mg / 18.0)
    }
}

enum Level {
    case low, normal, high

    init(mg: Double, low: Double, high: Double) {
        if mg < low { self = .low } else if mg > high { self = .high } else { self = .normal }
    }

    var title: String {
        switch self {
        case .low: return "منخفض"
        case .normal: return "طبيعي"
        case .high: return "مرتفع"
        }
    }

    var color: Color {
        switch self {
        case .low: return .orange
        case .normal: return .green
        case .high: return .red
        }
    }
}

enum Fmt {
    static let locale = Locale(identifier: "ar@numbers=latn")

    static let day: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEEE، d MMMM"
        return f
    }()

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "h:mm a"
        return f
    }()

    static let full: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    /// Accepts Arabic-Indic digits and Arabic decimal separators.
    static func parse(_ text: String) -> Double? {
        let map: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "٫": ".", ",": ".", "،": "."
        ]
        let cleaned = String(text.trimmingCharacters(in: .whitespaces).map { map[$0] ?? $0 })
        return Double(cleaned)
    }
}
