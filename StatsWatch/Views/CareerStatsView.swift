import SwiftUI

struct CareerStatsView: View {
    let viewModel: PlayerViewModel
    let heroKey: String? // nil = all-heroes
    let heroName: String

    private var categories: [CareerStatCategory] {
        if let key = heroKey {
            return viewModel.careerStatsForHero(key) ?? []
        }
        return viewModel.careerStatsAllHeroes() ?? []
    }

    // Show "best" and "hero_specific" categories at top for highlights
    private let highlightCategories = ["best", "hero_specific"]
    private let categoryOrder = ["best", "hero_specific", "combat", "game", "assists", "average", "match_awards", "miscellaneous"]

    var body: some View {
        ScrollView {
            if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text("No career stats available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                VStack(spacing: 16) {
                    // Highlights section
                    let bestStats = categories.first { $0.category == "best" }
                    if let best = bestStats, let stats = best.stats, !stats.isEmpty {
                        CareerHighlightsSection(stats: Array(stats.prefix(6)))
                    }

                    // All categories
                    let sorted = categories.sorted { a, b in
                        let ia = categoryOrder.firstIndex(of: a.category ?? "") ?? 99
                        let ib = categoryOrder.firstIndex(of: b.category ?? "") ?? 99
                        return ia < ib
                    }

                    ForEach(sorted) { category in
                        CareerCategorySection(category: category)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("\(heroName) Career Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Highlights
struct CareerHighlightsSection: View {
    let stats: [CareerStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
                Text("Personal Bests")
                    .font(.system(size: 16, weight: .bold))
            }
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(stats) { stat in
                    HighlightStatCard(stat: stat)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HighlightStatCard: View {
    let stat: CareerStat

    var body: some View {
        VStack(spacing: 6) {
            Text(stat.value?.displayString ?? "-")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(stat.label ?? stat.key ?? "")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.08), .orange.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Category Section
struct CareerCategorySection: View {
    let category: CareerStatCategory
    @State private var isExpanded = true

    private var categoryIcon: String {
        switch category.category {
        case "best": return "trophy.fill"
        case "combat": return "flame.fill"
        case "game": return "gamecontroller.fill"
        case "assists": return "hands.clap.fill"
        case "average": return "chart.line.uptrend.xyaxis"
        case "match_awards": return "medal.fill"
        case "hero_specific": return "star.circle.fill"
        case "miscellaneous": return "ellipsis.circle.fill"
        default: return "list.bullet"
        }
    }

    private var categoryColor: Color {
        switch category.category {
        case "best": return .orange
        case "combat": return .red
        case "game": return .blue
        case "assists": return .green
        case "average": return .purple
        case "match_awards": return .yellow
        case "hero_specific": return .cyan
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                        .frame(width: 20)
                    Text(category.label ?? category.category?.capitalized ?? "Stats")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("\(category.stats?.count ?? 0)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            if isExpanded, let stats = category.stats {
                Divider().padding(.horizontal, 14)
                VStack(spacing: 0) {
                    ForEach(stats) { stat in
                        HStack {
                            Text(stat.label ?? stat.key ?? "")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(stat.value?.displayString ?? "-")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
