import SwiftUI

struct HeroComparisonView: View {
    let viewModel: PlayerViewModel
    @State private var heroA: HeroWithStats?
    @State private var heroB: HeroWithStats?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Hero selectors
                HStack(spacing: 12) {
                    HeroSelector(
                        label: "Hero A",
                        selected: heroA,
                        allHeroes: viewModel.allHeroesSorted,
                        viewModel: viewModel,
                        color: .blue
                    ) { heroA = $0 }

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)

                    HeroSelector(
                        label: "Hero B",
                        selected: heroB,
                        allHeroes: viewModel.allHeroesSorted,
                        viewModel: viewModel,
                        color: .orange
                    ) { heroB = $0 }
                }
                .padding(.horizontal)

                if let a = heroA, let b = heroB {
                    // Comparison content
                    ComparisonHeader(a: a, b: b, viewModel: viewModel)

                    ComparisonStatsList(a: a, b: b)

                    // Dual radar chart
                    DualRadarSection(a: a, b: b, viewModel: viewModel)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 40))
                            .foregroundStyle(.quaternary)
                        Text("Select two heroes to compare")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Hero Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Hero Selector
struct HeroSelector: View {
    let label: String
    let selected: HeroWithStats?
    let allHeroes: [HeroWithStats]
    let viewModel: PlayerViewModel
    let color: Color
    let onSelect: (HeroWithStats) -> Void

    var body: some View {
        Menu {
            ForEach(allHeroes) { hero in
                Button {
                    onSelect(hero)
                } label: {
                    Text(viewModel.heroInfo(for: hero.key)?.name ?? hero.key.capitalized)
                }
            }
        } label: {
            VStack(spacing: 6) {
                if let hero = selected {
                    AsyncImage(url: viewModel.heroPortraitURL(for: hero.key)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(color.opacity(0.15))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(color)
                            }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 2))

                    Text(viewModel.heroInfo(for: hero.key)?.name ?? hero.key.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                } else {
                    Circle()
                        .strokeBorder(color.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "plus")
                                .foregroundStyle(color)
                        }

                    Text(label)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Comparison Header
struct ComparisonHeader: View {
    let a: HeroWithStats
    let b: HeroWithStats
    let viewModel: PlayerViewModel

    var body: some View {
        HStack {
            VStack(spacing: 2) {
                Text(String(format: "%.1f%%", a.stats.winrate ?? 0))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle((a.stats.winrate ?? 0) >= (b.stats.winrate ?? 0) ? .green : .secondary)
                Text("Win Rate")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Text("VS")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                Text(String(format: "%.1f%%", b.stats.winrate ?? 0))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle((b.stats.winrate ?? 0) >= (a.stats.winrate ?? 0) ? .green : .secondary)
                Text("Win Rate")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Stats Comparison List
struct ComparisonStatsList: View {
    let a: HeroWithStats
    let b: HeroWithStats

    var body: some View {
        VStack(spacing: 4) {
            CompStatRow(label: "Games", aVal: Double(a.stats.gamesPlayed ?? 0), bVal: Double(b.stats.gamesPlayed ?? 0), format: "%.0f")
            CompStatRow(label: "KDA", aVal: a.stats.kda ?? 0, bVal: b.stats.kda ?? 0, format: "%.2f")
            CompStatRow(label: "Elims/10min", aVal: a.stats.average?.eliminations ?? 0, bVal: b.stats.average?.eliminations ?? 0, format: "%.1f")
            CompStatRow(label: "Deaths/10min", aVal: a.stats.average?.deaths ?? 0, bVal: b.stats.average?.deaths ?? 0, format: "%.1f", lowerIsBetter: true)
            CompStatRow(label: "Dmg/10min", aVal: a.stats.average?.damage ?? 0, bVal: b.stats.average?.damage ?? 0, format: "%.0f")
            CompStatRow(label: "Heal/10min", aVal: a.stats.average?.healing ?? 0, bVal: b.stats.average?.healing ?? 0, format: "%.0f")
            CompStatRow(label: "Assists/10min", aVal: a.stats.average?.assists ?? 0, bVal: b.stats.average?.assists ?? 0, format: "%.1f")
        }
        .padding(.horizontal)
    }
}

struct CompStatRow: View {
    let label: String
    let aVal: Double
    let bVal: Double
    var format: String = "%.1f"
    var lowerIsBetter: Bool = false

    private var aWins: Bool {
        lowerIsBetter ? aVal < bVal : aVal > bVal
    }

    var body: some View {
        HStack {
            Text(String(format: format, aVal))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(aVal == bVal ? Color.primary : (aWins ? Color.blue : Color.secondary))
                .frame(width: 70, alignment: .trailing)

            // Bar visualization
            GeometryReader { geo in
                let total = aVal + bVal
                let aRatio = total > 0 ? CGFloat(aVal / total) : 0.5

                HStack(spacing: 1) {
                    Rectangle()
                        .fill(aWins ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2))
                        .frame(width: geo.size.width * aRatio)
                    Rectangle()
                        .fill(!aWins ? Color.orange.opacity(0.6) : Color.gray.opacity(0.2))
                        .frame(width: geo.size.width * (1 - aRatio))
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(height: 8)

            Text(String(format: format, bVal))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(aVal == bVal ? Color.primary : (!aWins ? Color.orange : Color.secondary))
                .frame(width: 70, alignment: .leading)
        }
        .padding(.vertical, 6)
        .overlay(alignment: .center) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Dual Radar
struct DualRadarSection: View {
    let a: HeroWithStats
    let b: HeroWithStats
    let viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("Radar Comparison")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            DualRadarChartView(
                dataA: radarData(for: a),
                dataB: radarData(for: b)
            )
            .frame(height: 260)
            .padding(.horizontal)

            HStack(spacing: 20) {
                LegendDot(color: .blue.opacity(0.6), label: viewModel.heroInfo(for: a.key)?.name ?? a.key.capitalized)
                LegendDot(color: .orange.opacity(0.6), label: viewModel.heroInfo(for: b.key)?.name ?? b.key.capitalized)
            }
            .font(.system(size: 12))
        }
    }

    private func radarData(for hero: HeroWithStats) -> [PlayerViewModel.RadarDataPoint] {
        let avg = hero.stats.average
        let deaths = avg?.deaths ?? 0
        let survivability = max(0, 1.0 - (deaths / 15.0))

        return [
            .init(label: "Elims", value: min(1, (avg?.eliminations ?? 0) / 25.0)),
            .init(label: "Assists", value: min(1, (avg?.assists ?? 0) / 15.0)),
            .init(label: "Survival", value: min(1, survivability)),
            .init(label: "Damage", value: min(1, (avg?.damage ?? 0) / 12000.0)),
            .init(label: "Healing", value: min(1, (avg?.healing ?? 0) / 8000.0)),
        ]
    }
}

// MARK: - Dual Radar Chart View
struct DualRadarChartView: View {
    let dataA: [PlayerViewModel.RadarDataPoint]
    let dataB: [PlayerViewModel.RadarDataPoint]
    let gridLevels = 5

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 40
            let sides = dataA.count

            ZStack {
                // Grid
                ForEach(1...gridLevels, id: \.self) { level in
                    PolygonShape(sides: sides, scale: CGFloat(level) / CGFloat(gridLevels))
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                // Axes
                ForEach(0..<sides, id: \.self) { i in
                    let angle = angleFor(index: i, total: sides)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pointOn(center: center, radius: radius, angle: angle))
                    }
                    .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                }

                // Data A
                let pointsA = dataA.enumerated().map { (i, d) in
                    pointOn(center: center, radius: radius * CGFloat(d.value), angle: angleFor(index: i, total: sides))
                }
                PolygonPath(points: pointsA)
                    .fill(Color.blue.opacity(0.15))
                PolygonPath(points: pointsA)
                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)

                // Data B
                let pointsB = dataB.enumerated().map { (i, d) in
                    pointOn(center: center, radius: radius * CGFloat(d.value), angle: angleFor(index: i, total: sides))
                }
                PolygonPath(points: pointsB)
                    .fill(Color.orange.opacity(0.15))
                PolygonPath(points: pointsB)
                    .stroke(Color.orange.opacity(0.6), lineWidth: 2)

                // Labels
                ForEach(0..<sides, id: \.self) { i in
                    let angle = angleFor(index: i, total: sides)
                    let pt = pointOn(center: center, radius: radius + 24, angle: angle)
                    Text(dataA[i].label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .position(pt)
                }
            }
        }
    }

    private func angleFor(index: Int, total: Int) -> Double {
        2 * .pi / Double(total) * Double(index) - .pi / 2
    }

    private func pointOn(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
    }
}
