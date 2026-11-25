import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ReadingStore
    @AppStorage("unit") private var unitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("lowLimit") private var low = 70.0
    @AppStorage("highLimit") private var high = 180.0
    @State private var confirmWipe = false

    var body: some View {
        NavigationStack {
            Form {
                Section("وحدة القياس") {
                    Picker("الوحدة", selection: $unitRaw) {
                        ForEach(GlucoseUnit.allCases) { u in
                            Text(u.title).tag(u.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Stepper("الحد الأدنى: \(Int(low)) mg/dL", value: $low, in: 40...150, step: 5)
                    Stepper("الحد الأعلى: \(Int(high)) mg/dL", value: $high, in: 100...300, step: 5)
                    Button("رجّع القيم الافتراضية (70 – 180)") {
                        low = 70
                        high = 180
                    }
                } header: {
                    Text("النطاق المستهدف")
                } footer: {
                    Text("حدّد النطاق اللي اتفقت عليه مع طبيبك. القراءات تحت الحد الأدنى تظهر بالبرتقالي، وفوق الحد الأعلى بالأحمر.")
                }

                Section("البيانات") {
                    ShareLink(item: store.exportCSV()) {
                        Label("تصدير القراءات (CSV)", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.readings.isEmpty)
                    Button(role: .destructive) {
                        confirmWipe = true
                    } label: {
                        Label("حذف كل القراءات", systemImage: "trash")
                    }
                    .disabled(store.readings.isEmpty)
                }

                Section {
                    Text("هذا التطبيق للمتابعة الشخصية فقط، وما يغني عن استشارة الطبيب.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("الإعدادات")
            .confirmationDialog("تبي تحذف كل القراءات؟ ما تقدر ترجعها بعدين.", isPresented: $confirmWipe, titleVisibility: .visible) {
                Button("حذف الكل", role: .destructive) { store.deleteAll() }
            }
        }
    }
}
