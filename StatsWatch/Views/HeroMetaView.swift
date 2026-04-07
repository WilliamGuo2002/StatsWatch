import SwiftUI

struct HeroMetaView: View {
    let viewModel: PlayerViewModel
    @State private var heroStats: [HeroGlobalStat] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRole: String? = nil
    @State private var sortBy: MetaSortOption = .pickrate
    @State private var selectedGamemode: String = "competitive"

    enum MetaSortOption: String, CaseIterable {
        case pickrate = "Pick Rate"
        case winrate = "Win Rate"
    }

    private let api = OverwatchAPIService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Gamemode toggle
                HStack(spacing: 0) {
                    ForEach(["competitive", "quickplay"], id: \.self) { mode in
                        Button {
                            selectedGamemode = mode
                            Task { await loadStats() }
                        } label: {
                            Text(mode == "competitive" ? "Competitive" : "Quick Play")
                                .font(.system(size: 13, weight: selectedGamemode == mode ? .bold : .medium))
                                .foregroundStyle(selectedGamemode == mode ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedGamemode == mode ? Color.blue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(3)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

                // Role filter
                HStack(spacing: 8) {
                    RoleFilterChip(label: "All", icon: "circle.grid.cross", isSelected: selectedRole == nil) {
                        selectedRole = nil
                    }
                    RoleFilterChip(label: "Tank", icon: "shield.fill", isSelected: selectedRole == "tank", color: .blue) {
                        selectedRole = "tank"
                    }
                    RoleFilterChip(label: "DPS", icon: "bolt.fill", isSelected: selectedRole == "damage", color: .red) {
                        selectedRole = "damage"
                    }
                    RoleFilterChip(label: "Support", icon: "cross.fill", isSelected: selectedRole == "support", color: .green) {
                        selectedRole = "support"
                    }
                }
                .padding(.horizontal)

                // Sort toggle
                HStack {
                    Text("Sort by")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Picker("Sort", selection: $sortBy) {
                        ForEach(MetaSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    Spacer()
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    // Stats list
                    let filtered = filteredAndSorted
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, stat in
                        MetaHeroRow(
                            rank: index + 1,
                            stat: stat,
                            heroInfo: viewModel.heroInfo(for: stat.hero),
                            portraitURL: viewModel.heroPortraitURL(for: stat.hero),
                            maxPickrate: filtered.compactMap(\.pickrate).max() ?? 1,
                            sortBy: sortBy
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Hero Meta")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Ensure heroes are loaded for portraits/names
            if viewModel.heroes.isEmpty {
                do {
                    viewModel.heroes = try await OverwatchAPIService.shared.getHeroes()
                } catch {}
            }
            await loadStats()
        }
    }

    private var filteredAndSorted: [HeroGlobalStat] {
        var list = heroStats
        if let role = selectedRole {
            list = list.filter { HeroRoles.role(for: $0.hero) == role }
        }
        switch sortBy {
        case .pickrate:
            list.sort { ($0.pickrate ?? 0) > ($1.pickrate ?? 0) }
        case .winrate:
            list.sort { ($0.winrate ?? 0) > ($1.winrate ?? 0) }
        }
        return list
    }

    private func loadStats() async {
        isLoading = true
        errorMessage = nil
        do {
            heroStats = try await api.getHeroGlobalStats(platform: "pc", gamemode: selectedGamemode)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct RoleFilterChip: View {
    let label: String
    let icon: String
    var isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct MetaHeroRow: View {
    let rank: Int
    let stat: HeroGlobalStat
    let heroInfo: HeroInfo?
    let portraitURL: URL?
    let maxPickrate: Double
    let sortBy: HeroMetaView.MetaSortOption

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Portrait
            AsyncImage(url: portraitURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(roleColor.opacity(0.15))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(roleColor)
                            .font(.system(size: 14))
                    }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().stroke(roleColor.opacity(0.3), lineWidth: 1.5))

            // Name + role
            VStack(alignment: .leading, spacing: 3) {
                Text(heroInfo?.name ?? stat.hero.capitalized)
                    .font(.system(size: 14, weight: .semibold))
                Text(HeroRoles.role(for: stat.hero).capitalized)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Bar + stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    // Pick rate
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(String(format: "%.1f%%", stat.pickrate ?? 0))
                            .font(.system(size: 13, weight: sortBy == .pickrate ? .bold : .medium, design: .rounded))
                            .foregroundStyle(sortBy == .pickrate ? .primary : .secondary)
                        Text("Pick")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }

                    // Win rate
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(String(format: "%.1f%%", stat.winrate ?? 0))
                            .font(.system(size: 13, weight: sortBy == .winrate ? .bold : .medium, design: .rounded))
                            .foregroundStyle(winrateColor)
                        Text("Win")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }

                // Bar
                GeometryReader { geo in
                    let ratio = sortBy == .pickrate
                        ? CGFloat((stat.pickrate ?? 0) / maxPickrate)
                        : CGFloat((stat.winrate ?? 0) / 100)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor.opacity(0.4))
                        .frame(width: geo.size.width * min(1, ratio), height: 4)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(width: 120, height: 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var roleColor: Color {
        switch HeroRoles.role(for: stat.hero) {
        case "tank": return .blue
        case "damage": return .red
        case "support": return .green
        default: return .gray
        }
    }

    private var winrateColor: Color {
        let wr = stat.winrate ?? 0
        if wr >= 52 { return .green }
        if wr >= 48 { return .primary }
        return .red
    }

    private var barColor: Color {
        sortBy == .pickrate ? roleColor : winrateColor
    }
}
