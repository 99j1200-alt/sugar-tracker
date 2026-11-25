import SwiftUI

struct ReadingsView: View {
    @EnvironmentObject private var store: ReadingStore
    @AppStorage("unit") private var unitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("lowLimit") private var low = 70.0
    @AppStorage("highLimit") private var high = 180.0

    @State private var showAdd = false
    @State private var editing: Reading?

    private var unit: GlucoseUnit { GlucoseUnit(rawValue: unitRaw) ?? .mgdl }

    private struct DayGroup: Identifiable {
        let day: Date
        let items: [Reading]
        var id: Date { day }
    }

    private var grouped: [DayGroup] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: store.readings) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { day in
            DayGroup(day: day, items: (dict[day] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.readings.isEmpty {
                    emptyState
                } else {
                    List {
                        if let last = store.latest {
                            Section { LatestCard(reading: last, unit: unit, low: low, high: high) }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                        ForEach(grouped) { group in
                            Section(Fmt.day.string(from: group.day)) {
                                ForEach(group.items) { r in
                                    Button { editing = r } label: {
                                        ReadingRow(reading: r, unit: unit, low: low, high: high)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    store.delete(ids: offsets.map { group.items[$0].id })
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("قراءات السكر")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                ReadingForm(original: nil, unit: unit)
            }
            .sheet(item: $editing) { r in
                ReadingForm(original: r, unit: unit)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 64))
                .foregroundStyle(.teal)
            Text("ما فيه قراءات للحين").font(.title2.bold())
            Text("سجّل أول قراءة سكر عشان تبدأ تتابع.")
                .foregroundStyle(.secondary)
            Button {
                showAdd = true
            } label: {
                Label("إضافة قراءة", systemImage: "plus")
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct LatestCard: View {
    let reading: Reading
    let unit: GlucoseUnit
    let low: Double
    let high: Double

    var body: some View {
        let level = Level(mg: reading.value, low: low, high: high)
        VStack(alignment: .leading, spacing: 8) {
            Text("آخر قراءة").font(.subheadline).foregroundStyle(.white.opacity(0.85))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(unit.format(reading.value))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(unit.title).font(.headline)
                Spacer()
                Text(level.title)
                    .font(.headline)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.white.opacity(0.25), in: Capsule())
            }
            Text("\(reading.context.title) · \(Fmt.day.string(from: reading.date)) · \(Fmt.time.string(from: reading.date))")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [level.color, level.color.opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .padding(.vertical, 6)
    }
}

struct ReadingRow: View {
    let reading: Reading
    let unit: GlucoseUnit
    let low: Double
    let high: Double

    var body: some View {
        let level = Level(mg: reading.value, low: low, high: high)
        HStack(spacing: 12) {
            Image(systemName: reading.context.icon)
                .frame(width: 36, height: 36)
                .background(level.color.opacity(0.15), in: Circle())
                .foregroundStyle(level.color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(unit.format(reading.value)).font(.title3.bold())
                    Text(unit.title).font(.caption).foregroundStyle(.secondary)
                }
                Text("\(reading.context.title) · \(Fmt.time.string(from: reading.date))")
                    .font(.subheadline).foregroundStyle(.secondary)
                if !reading.note.isEmpty {
                    Text(reading.note).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            Text(level.title)
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(level.color.opacity(0.15), in: Capsule())
                .foregroundStyle(level.color)
        }
        .contentShape(Rectangle())
    }
}

struct ReadingForm: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ReadingStore

    let original: Reading?
    let unit: GlucoseUnit

    @State private var valueText: String
    @State private var date: Date
    @State private var context: MealContext
    @State private var note: String
    @State private var confirmDelete = false

    init(original: Reading?, unit: GlucoseUnit) {
        self.original = original
        self.unit = unit
        let now = Date()
        _valueText = State(initialValue: original.map { unit.format($0.value) } ?? "")
        _date = State(initialValue: original?.date ?? now)
        _context = State(initialValue: original?.context ?? MealContext.guess(for: now))
        _note = State(initialValue: original?.note ?? "")
    }

    private var mgValue: Double? {
        guard let v = Fmt.parse(valueText) else { return nil }
        let mg = unit.toMg(v)
        return (10...800).contains(mg) ? mg : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("القراءة") {
                    HStack {
                        TextField(unit == .mgdl ? "مثال: 110" : "مثال: 6.1", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text(unit.title).foregroundStyle(.secondary)
                    }
                    if !valueText.isEmpty && mgValue == nil {
                        Text("القيمة غير صحيحة").font(.caption).foregroundStyle(.red)
                    }
                }
                Section("متى؟") {
                    Picker("التوقيت", selection: $context) {
                        ForEach(MealContext.allCases) { c in
                            Label(c.title, systemImage: c.icon).tag(c)
                        }
                    }
                    DatePicker("التاريخ والوقت", selection: $date, in: ...Date())
                }
                Section("ملاحظات") {
                    TextField("اختياري (أكل، رياضة، دواء…)", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
                if original != nil {
                    Section {
                        Button("حذف القراءة", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(original == nil ? "قراءة جديدة" : "تعديل القراءة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") { save() }
                        .bold()
                        .disabled(mgValue == nil)
                }
            }
            .confirmationDialog("متأكد تبي تحذف هذي القراءة؟", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("حذف", role: .destructive) {
                    if let original { store.delete(ids: [original.id]) }
                    dismiss()
                }
            }
        }
    }

    private func save() {
        guard let mg = mgValue else { return }
        var r = original ?? Reading(value: mg, date: date, context: context)
        r.value = mg
        r.date = date
        r.context = context
        r.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        store.upsert(r)
        dismiss()
    }
}
