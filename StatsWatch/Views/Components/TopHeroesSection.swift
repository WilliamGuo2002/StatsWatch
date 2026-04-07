import SwiftUI

struct TopHeroesSection: View {
    let viewModel: PlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Most Played Heroes")
                    .font(.system(size: 18, weight: .bold))

                Spacer()

                NavigationLink {
                    AllHeroesView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 4) {
                        Text("All Heroes")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // Top 3 heroes
            HStack(spacing: 10) {
                ForEach(Array(viewModel.topHeroes.enumerated()), id: \.element.id) { index, hero in
                    NavigationLink {
                        HeroDetailView(hero: hero, viewModel: viewModel)
                    } label: {
                        TopHeroCard(
                            hero: hero,
                            rank: index + 1,
                            portraitURL: viewModel.heroPortraitURL(for: hero.key),
                            heroName: viewModel.heroInfo(for: hero.key)?.name ?? hero.key.capitalized,
                            heroRole: HeroRoles.role(for: hero.key)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Stats bar for top hero
            if let topHero = viewModel.topHeroes.first {
                TopHeroStatsBar(hero: topHero)
                    .padding(.horizontal)
            }
        }
    }
}

struct TopHeroCard: View {
    let hero: HeroWithStats
    let rank: Int
    let portraitURL: URL?
    let heroName: String
    let heroRole: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: portraitURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [roleColor.opacity(0.3), roleColor.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            Image(systemName: roleIcon)
                                .font(.system(size: 30))
                                .foregroundStyle(roleColor.opacity(0.5))
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10
                ))

                RankBadgeView(rank: rank)
                    .padding(6)
            }

            HStack(spacing: 4) {
                Image(systemName: roleIcon)
                    .font(.system(size: 10))
                    .foregroundStyle(roleColor)

                Text(heroName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var roleIcon: String {
        switch heroRole {
        case "tank": return "shield.fill"
        case "damage": return "bolt.fill"
        case "support": return "cross.fill"
        default: return "circle.fill"
        }
    }

    private var roleColor: Color {
        switch heroRole {
        case "tank": return .blue
        case "damage": return .red
        case "support": return .green
        default: return .gray
        }
    }
}

struct RankBadgeView: View {
    let rank: Int

    var body: some View {
        Text(rankText)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(badgeColor)
            )
    }

    private var rankText: String {
        switch rank {
        case 1: return "1ST"
        case 2: return "2ND"
        case 3: return "3RD"
        default: return "\(rank)TH"
        }
    }

    private var badgeColor: Color {
        switch rank {
        case 1: return .orange
        case 2: return .gray
        case 3: return .brown
        default: return .gray
        }
    }
}

struct TopHeroStatsBar: View {
    let hero: HeroWithStats

    var body: some View {
        HStack(spacing: 0) {
            MiniHeroStat(title: "Win Rate", value: String(format: "%.1f%%", hero.stats.winrate ?? 0))
            Divider().frame(height: 30)
            MiniHeroStat(title: "KDA", value: String(format: "%.2f", hero.stats.kda ?? 0))
            Divider().frame(height: 30)
            MiniHeroStat(title: "Time", value: formatTimePlayedShort(seconds: hero.stats.timePlayed ?? 0))
            Divider().frame(height: 30)
            MiniHeroStat(title: "Games", value: "\(hero.stats.gamesPlayed ?? 0)")
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MiniHeroStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - All Heroes View
struct AllHeroesView: View {
    let viewModel: PlayerViewModel

    var body: some View {
        List {
            ForEach(viewModel.allHeroesSorted) { hero in
                NavigationLink {
                    HeroDetailView(hero: hero, viewModel: viewModel)
                } label: {
                    HeroListRow(
                        hero: hero,
                        heroName: viewModel.heroInfo(for: hero.key)?.name ?? hero.key.capitalized,
                        portraitURL: viewModel.heroPortraitURL(for: hero.key)
                    )
                }
            }
        }
        .navigationTitle("All Heroes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeroListRow: View {
    let hero: HeroWithStats
    let heroName: String
    let portraitURL: URL?

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: portraitURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(heroName)
                    .font(.system(size: 15, weight: .semibold))

                Text("\(hero.stats.gamesPlayed ?? 0) games • \(formatTimePlayedShort(seconds: hero.stats.timePlayed ?? 0))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f%%", hero.stats.winrate ?? 0))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle((hero.stats.winrate ?? 0) >= 50 ? .green : .red)

                Text("KDA \(String(format: "%.2f", hero.stats.kda ?? 0))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
