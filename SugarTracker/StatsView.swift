import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: ReadingStore
    @AppStorage("unit") private var unitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("lowLimit") private var low = 70.0
    @AppStorage("highLimit") private var high = 180.0
    @State private var days = 7

    private var unit: GlucoseUnit { GlucoseUnit(rawValue: unitRaw) ?? .mgdl }
    private var data: [Reading] { store.readings(lastDays: days) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("الفترة", selection: $days) {
                        Text("٧ أيام").tag(7)
                        Text("٣٠ يوم").tag(30)
                        Text("٩٠ يوم").tag(90)
                    }
                    .pickerStyle(.segmented)

                    if data.isEmpty {
                        Text("ما فيه قراءات في هذي الفترة.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        chart
                        summary
                        byContext
                        Text("المعدل التراكمي (A1c) تقدير تقريبي من متوسط القراءات، وما يغني عن تحليل المختبر.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("الإحصائيات")
        }
    }

    private var chart: some View {
        Chart {
            RuleMark(y: .value("الحد الأدنى", unit.fromMg(low)))
                .foregroundStyle(.orange.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            RuleMark(y: .value("الحد الأعلى", unit.fromMg(high)))
                .foregroundStyle(.red.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            ForEach(data) { r in
                LineMark(x: .value("الوقت", r.date), y: .value("السكر", unit.fromMg(r.value)))
                    .foregroundStyle(.teal.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("الوقت", r.date), y: .value("السكر", unit.fromMg(r.value)))
                    .foregroundStyle(Level(mg: r.value, low: low, high: high).color)
            }
        }
        .frame(height: 240)
        .environment(\.layoutDirection, .leftToRight)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var summary: some View {
        let values = data.map(\.value)
        let avg = values.reduce(0, +) / Double(values.count)
        let inRange = values.filter { $0 >= low && $0 <= high }.count
        let pct = Int((Double(inRange) / Double(values.count) * 100).rounded())
        let a1c = (avg + 46.7) / 28.7

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "المتوسط", value: unit.format(avg), sub: unit.title, color: .teal)
            StatCard(title: "داخل النطاق", value: "\(pct)%", sub: "\(inRange) من \(values.count)", color: .green)
            StatCard(title: "أقل قراءة", value: unit.format(values.min() ?? 0), sub: unit.title, color: .orange)
            StatCard(title: "أعلى قراءة", value: unit.format(values.max() ?? 0), sub: unit.title, color: .red)
            StatCard(title: "عدد القراءات", value: "\(values.count)", sub: "قراءة", color: .blue)
            StatCard(title: "A1c تقديري", value: String(format: "%.1f%%", a1c), sub: "تقريبي", color: .purple)
        }
    }

    private var byContext: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("المتوسط حسب التوقيت").font(.headline)
            ForEach(MealContext.allCases) { c in
                let vals = data.filter { $0.context == c }.map(\.value)
                if !vals.isEmpty {
                    let avg = vals.reduce(0, +) / Double(vals.count)
                    HStack {
                        Label(c.title, systemImage: c.icon)
                        Spacer()
                        Text("\(unit.format(avg)) \(unit.title)").bold()
                            .foregroundStyle(Level(mg: avg, low: low, high: high).color)
                        Text("(\(vals.count))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let sub: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.system(.title, design: .rounded).bold()).foregroundStyle(color)
            Text(sub).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
