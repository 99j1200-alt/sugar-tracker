import Foundation

@MainActor
final class ReadingStore: ObservableObject {
    @Published private(set) var readings: [Reading] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("readings.json")
    }()

    init() {
        load()
    }

    var latest: Reading? { readings.max { $0.date < $1.date } }

    func upsert(_ reading: Reading) {
        if let i = readings.firstIndex(where: { $0.id == reading.id }) {
            readings[i] = reading
        } else {
            readings.append(reading)
        }
        save()
    }

    func delete(ids: [UUID]) {
        readings.removeAll { ids.contains($0.id) }
        save()
    }

    func deleteAll() {
        readings.removeAll()
        save()
    }

    func readings(lastDays days: Int) -> [Reading] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? .distantPast
        return readings.filter { $0.date >= start }.sorted { $0.date < $1.date }
    }

    func exportCSV() -> URL {
        var lines = ["date,value_mg_dl,context,note"]
        for r in readings.sorted(by: { $0.date < $1.date }) {
            let note = r.note.replacingOccurrences(of: "\"", with: "\"\"")
            lines.append("\(Fmt.full.string(from: r.date)),\(Int(r.value.rounded())),\(r.context.title),\"\(note)\"")
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sugar-readings.csv")
        // BOM so Excel opens Arabic text correctly.
        try? ("\u{FEFF}" + lines.joined(separator: "\n")).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Reading].self, from: data) else { return }
        readings = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(readings) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
