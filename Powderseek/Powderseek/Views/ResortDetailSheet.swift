import SwiftUI

struct ResortDetailSheet: View {
    let slug: String
    @Environment(\.dismiss) private var dismiss

    // @State holds the loaded detail — nil while loading, populated after fetch.
    @State private var detail: ResortDetail? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    private let api = APIClient()
    private let months = ["Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let d = detail {
                    resortContent(d)
                } else {
                    Text(errorMessage ?? "Failed to load resort.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(detail?.name ?? "Resort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        // .task fires when the view appears and is automatically cancelled
        // if the view disappears before it finishes.
        .task {
            await loadDetail()
        }
    }

    // MARK: - Main content scroll view

    private func resortContent(_ d: ResortDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Ski-only warning banner
                if !d.snowboardAllowed {
                    HStack(spacing: 8) {
                        Text("⛷")
                        Text("Ski only — snowboarding not permitted")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                }

                // Out-of-season warning banner
                if !d.isInSeason {
                    HStack(spacing: 8) {
                        Text("❄️")
                        Text("Closed — currently out of season (\(months[d.seasonStartMonth - 1])–\(months[d.seasonEndMonth - 1]))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.4), lineWidth: 1))
                }

                // Snow conditions
                sectionHeader("Snow Conditions")
                let today = d.forecastDays.first
                HStack(spacing: 12) {
                    StatCard(label: "New snow", value: today?.newSnowCm.map { "\(Int($0)) cm" } ?? "—")
                    StatCard(label: "7-day total", value: today?.cumulative7dCm.map { "\(Int($0)) cm" } ?? "—")
                    StatCard(label: "Base", value: today?.baseDepthCm.map { "\($0) cm" } ?? "—")
                }

                // 7-day bar chart
                if !d.forecastDays.isEmpty {
                    sectionHeader("7-Day Forecast")
                    SnowBarChart(days: d.forecastDays)
                }

                // Terrain difficulty mix
                if let mix = d.difficultyMix, !mix.isEmpty {
                    sectionHeader("Terrain Breakdown")
                    DifficultyBar(mix: mix)
                }

                // Mountain stats
                sectionHeader("Mountain")
                VStack(spacing: 8) {
                    DetailRow(label: "Vertical drop", value: "\(d.verticalDropM) m")
                    DetailRow(label: "Base elevation", value: "\(d.elevationBaseM) m")
                    DetailRow(label: "Summit", value: "\(d.elevationSummitM) m")
                    DetailRow(label: "Season", value: "\(months[d.seasonStartMonth - 1]) – \(months[d.seasonEndMonth - 1])")
                    if let snow = d.avgAnnualSnowfallCm {
                        DetailRow(label: "Avg snowfall", value: "\(snow) cm/yr")
                    }
                    if let tier = d.budgetTier {
                        DetailRow(label: "Budget", value: tier.capitalized)
                    }
                    DetailRow(label: "Airport", value: "\(d.nearestAirport) (\(d.airportDriveMinutes) min drive)")
                }

                // Tags
                if !d.terrainTags.isEmpty {
                    sectionHeader("Terrain")
                    TagCloud(tags: d.terrainTags)
                }
                if !d.vibeTags.isEmpty {
                    sectionHeader("Vibe")
                    TagCloud(tags: d.vibeTags)
                }
            }
            .padding()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
            .kerning(0.8)
    }

    // MARK: - Load

    private func loadDetail() async {
        isLoading = true
        do {
            detail = try await api.fetchResortDetail(slug: slug)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Sub-components

private struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct SnowBarChart: View {
    let days: [ForecastDay]

    private var maxSnow: Double {
        max(days.map { $0.newSnowCm ?? 0 }.max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(days) { day in
                let cm = day.newSnowCm ?? 0
                let fraction = cm / maxSnow
                // Label the day of week from the date string
                let label = dayLabel(from: day.forecastDate)

                VStack(spacing: 4) {
                    if cm > 0 {
                        Text("\(Int(cm))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    // GeometryReader reads the available height so bars scale correctly.
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(height: max(geo.size.height * fraction, 3))
                        }
                    }
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 4)

        Text("cm / day")
            .font(.caption2)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func dayLabel(from dateStr: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateStr) else { return "" }
        let out = DateFormatter()
        out.dateFormat = "EEE"
        return String(out.string(from: date).prefix(2))
    }
}

private struct DifficultyBar: View {
    let mix: [String: Int]
    private let order = ["beginner", "intermediate", "advanced", "expert"]
    private let colors: [String: Color] = [
        "beginner": .green,
        "intermediate": .blue,
        "advanced": Color(.darkGray),
        "expert": .red,
    ]

    var body: some View {
        let total = Double(order.compactMap { mix[$0] }.reduce(0, +))
        VStack(alignment: .leading, spacing: 8) {
            // Stacked bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(order, id: \.self) { key in
                        if let pct = mix[key], pct > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colors[key] ?? .gray)
                                .frame(width: geo.size.width * Double(pct) / total)
                        }
                    }
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Legend
            HStack(spacing: 12) {
                ForEach(order, id: \.self) { key in
                    if let pct = mix[key], pct > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colors[key] ?? .gray)
                                .frame(width: 8, height: 8)
                            Text("\(key.capitalized) \(pct)%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

private struct TagCloud: View {
    let tags: [String]

    var body: some View {
        // FlowLayout isn't built into SwiftUI yet; we use a wrapping HStack simulation.
        // For a real app you'd use a custom Layout — but this works for a small tag list.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.secondary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(.separator), lineWidth: 1))
                }
            }
        }
    }
}
