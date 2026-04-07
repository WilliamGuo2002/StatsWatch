import SwiftUI

// MARK: - Tier List Section
struct HeroTierListSection: View {
    let viewModel: PlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hero Tier List")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("Based on your stats")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            let tiers = computeTiers()

            ForEach(tiers, id: \.tier) { tierGroup in
                if !tierGroup.heroes.isEmpty {
                    TierRow(
                        tier: tierGroup.tier,
                        heroes: tierGroup.heroes,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private func computeTiers() -> [TierGroup] {
        let heroes = viewModel.allHeroesSorted.filter { ($0.stats.gamesPlayed ?? 0) >= 3 }
        guard !heroes.isEmpty else { return [] }

        // Score each hero: weighted combination of winrate, KDA, and playtime
        let scored = heroes.map { hero -> (HeroWithStats, Double) in
            let wr = hero.stats.winrate ?? 0
            let kda = hero.stats.kda ?? 0
            let games = Double(hero.stats.gamesPlayed ?? 0)

            // Weighted score: winrate matters most, KDA second, games for confidence
            let gameWeight = min(1.0, games / 30.0) // confidence scaling
            let score = (wr * 0.5 + kda * 8.0 + games * 0.1) * (0.5 + 0.5 * gameWeight)
            return (hero, score)
        }.sorted { $0.1 > $1.1 }

        guard let maxScore = scored.first?.1, maxScore > 0 else { return [] }

        // Assign tiers based on percentile of max score
        var s: [HeroWithStats] = []
        var a: [HeroWithStats] = []
        var b: [HeroWithStats] = []
        var c: [HeroWithStats] = []
        var d: [HeroWithStats] = []

        for (hero, score) in scored {
            let ratio = score / maxScore
            if ratio >= 0.85 {
                s.append(hero)
            } else if ratio >= 0.65 {
                a.append(hero)
            } else if ratio >= 0.45 {
                b.append(hero)
            } else if ratio >= 0.25 {
                c.append(hero)
            } else {
                d.append(hero)
            }
        }

        return [
            TierGroup(tier: "S", heroes: s),
            TierGroup(tier: "A", heroes: a),
            TierGroup(tier: "B", heroes: b),
            TierGroup(tier: "C", heroes: c),
            TierGroup(tier: "D", heroes: d),
        ]
    }
}

struct TierGroup {
    let tier: String
    let heroes: [HeroWithStats]
}

struct TierRow: View {
    let tier: String
    let heroes: [HeroWithStats]
    let viewModel: PlayerViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Tier badge
            Text(tier)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(tierColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Hero portraits
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(heroes) { hero in
                        VStack(spacing: 3) {
                            AsyncImage(url: viewModel.heroPortraitURL(for: hero.key)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(tierColor.opacity(0.2))
                                    .overlay {
                                        Text(String(hero.key.prefix(1)).uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(tierColor)
                                    }
                            }
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(tierColor.opacity(0.4), lineWidth: 1.5)
                            )

                            Text(String(format: "%.0f%%", hero.stats.winrate ?? 0))
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(winrateColor(hero.stats.winrate ?? 0))
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(tierColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var tierColor: Color {
        switch tier {
        case "S": return .red
        case "A": return .orange
        case "B": return .blue
        case "C": return .teal
        case "D": return .gray
        default: return .gray
        }
    }

    private func winrateColor(_ wr: Double) -> Color {
        if wr >= 55 { return .green }
        if wr >= 45 { return .primary }
        return .red
    }
}
