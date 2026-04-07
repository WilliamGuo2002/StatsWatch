import Foundation
import SwiftUI

@Observable
class PlayerViewModel {
    var searchText = ""
    var searchResults: [PlayerSearchResult] = []
    var isSearching = false
    var searchError: String?
    var directLookupPlayerId: String?

    var playerSummary: PlayerSummary?
    var statsSummary: PlayerStatsSummary?
    var careerStats: [String: [CareerStatCategory]]?
    var heroGlobalStats: [HeroGlobalStat] = []
    var heroes: [HeroInfo] = []
    var isLoadingProfile = false
    var profileError: String?

    var selectedMode: GameMode = .quickplay
    var showExpandedStats = false
    var currentPlayerId: String?

    private let api = OverwatchAPIService.shared

    // MARK: - Search
    func searchPlayers() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        searchError = nil
        searchResults = []
        directLookupPlayerId = nil

        // If input contains #, convert to - and try direct lookup
        if query.contains("#") {
            let playerId = query.replacingOccurrences(of: "#", with: "-")
            do {
                let summary = try await api.getPlayerSummary(playerId: playerId)
                directLookupPlayerId = playerId
                let result = PlayerSearchResult(
                    playerId: playerId,
                    name: summary.username,
                    avatar: summary.avatar,
                    namecard: summary.namecard,
                    title: summary.title,
                    careerUrl: nil,
                    blizzardId: nil,
                    lastUpdatedAt: nil,
                    isPublic: true
                )
                searchResults = [result]
                isSearching = false
                return
            } catch {
                // Direct lookup failed, fallback to search
            }
        }

        // Search by name
        let searchName = query.split(separator: "#").first.map(String.init) ?? query
        do {
            let response = try await api.searchPlayers(name: searchName)
            searchResults = response.results
            if response.results.isEmpty {
                searchError = "No players found for \"\(searchName)\""
            }
        } catch {
            searchError = error.localizedDescription
        }

        isSearching = false
    }

    // MARK: - Load Player Profile
    func loadPlayerProfile(playerId: String) async {
        currentPlayerId = playerId
        isLoadingProfile = true
        profileError = nil
        statsSummary = nil

        async let summaryTask: () = loadSummary(playerId: playerId)
        async let statsTask: () = loadStats(playerId: playerId)
        async let careerTask: () = loadCareerStats(playerId: playerId)
        async let heroesTask: () = loadHeroesIfNeeded()
        async let globalStatsTask: () = loadHeroGlobalStats()

        await summaryTask
        await statsTask
        await careerTask
        await heroesTask
        await globalStatsTask

        isLoadingProfile = false
    }

    private func loadSummary(playerId: String) async {
        do {
            playerSummary = try await api.getPlayerSummary(playerId: playerId)
        } catch {
            profileError = error.localizedDescription
        }
    }

    // MARK: - Switch Game Mode
    func switchMode(_ mode: GameMode) async {
        guard mode != selectedMode, let playerId = currentPlayerId else { return }
        selectedMode = mode
        showExpandedStats = false
        statsSummary = nil
        careerStats = nil

        async let statsTask: () = loadStats(playerId: playerId)
        async let careerTask: () = loadCareerStats(playerId: playerId)
        await statsTask
        await careerTask
    }

    private func loadStats(playerId: String) async {
        do {
            statsSummary = try await api.getPlayerStatsSummary(
                playerId: playerId,
                gamemode: selectedMode
            )
        } catch {
            if profileError == nil {
                profileError = error.localizedDescription
            }
        }
    }

    private func loadCareerStats(playerId: String) async {
        do {
            careerStats = try await api.getPlayerCareerStats(playerId: playerId, gamemode: selectedMode)
        } catch {
            // Non-critical, career stats are supplementary
        }
    }

    private func loadHeroGlobalStats() async {
        guard heroGlobalStats.isEmpty else { return }
        do {
            heroGlobalStats = try await api.getHeroGlobalStats()
        } catch {
            // Non-critical
        }
    }

    func heroGlobalWinrate(for heroKey: String) -> Double? {
        heroGlobalStats.first { $0.hero == heroKey }?.winrate
    }

    func heroGlobalPickrate(for heroKey: String) -> Double? {
        heroGlobalStats.first { $0.hero == heroKey }?.pickrate
    }

    func careerStatsForHero(_ heroKey: String) -> [CareerStatCategory]? {
        careerStats?[heroKey]
    }

    func careerStatsAllHeroes() -> [CareerStatCategory]? {
        careerStats?["all-heroes"]
    }

    private func loadHeroesIfNeeded() async {
        guard heroes.isEmpty else { return }
        do {
            heroes = try await api.getHeroes()
        } catch {
            // Non-critical
        }
    }

    // MARK: - Computed: General Stats
    var overallWinRate: Double {
        statsSummary?.general?.winrate ?? 0
    }

    var overallGamesPlayed: Int {
        statsSummary?.general?.gamesPlayed ?? 0
    }

    var overallGamesWon: Int {
        statsSummary?.general?.gamesWon ?? 0
    }

    var overallKDA: Double {
        statsSummary?.general?.kda ?? 0
    }

    var totalEliminations: Int {
        statsSummary?.general?.total?.eliminations ?? 0
    }

    var totalDeaths: Int {
        statsSummary?.general?.total?.deaths ?? 0
    }

    var totalAssists: Int {
        statsSummary?.general?.total?.assists ?? 0
    }

    var totalPlayTimeSeconds: Int {
        statsSummary?.general?.timePlayed ?? 0
    }

    var totalPlayTimeHours: Int {
        totalPlayTimeSeconds / 3600
    }

    // Per 10min stats (from average field)
    var elimsPer10: Double { statsSummary?.general?.average?.eliminations ?? 0 }
    var deathsPer10: Double { statsSummary?.general?.average?.deaths ?? 0 }
    var assistsPer10: Double { statsSummary?.general?.average?.assists ?? 0 }
    var damagePer10: Double { statsSummary?.general?.average?.damage ?? 0 }
    var healingPer10: Double { statsSummary?.general?.average?.healing ?? 0 }

    // MARK: - Computed: Top Heroes
    var topHeroes: [HeroWithStats] {
        guard let heroDict = statsSummary?.heroes else { return [] }
        return heroDict
            .map { HeroWithStats(key: $0.key, stats: $0.value) }
            .sorted { $0.stats.timePlayedHours > $1.stats.timePlayedHours }
            .prefix(3)
            .map { $0 }
    }

    var allHeroesSorted: [HeroWithStats] {
        guard let heroDict = statsSummary?.heroes else { return [] }
        return heroDict
            .map { HeroWithStats(key: $0.key, stats: $0.value) }
            .sorted { $0.stats.timePlayedHours > $1.stats.timePlayedHours }
    }

    func heroInfo(for key: String) -> HeroInfo? {
        heroes.first { $0.key == key }
    }

    func heroPortraitURL(for key: String) -> URL? {
        if let info = heroInfo(for: key), let portrait = info.portrait {
            return URL(string: portrait)
        }
        return nil
    }

    // MARK: - Computed: Role Stats
    var roleStats: [RoleWithStats] {
        guard let roleDict = statsSummary?.roles else { return [] }
        let order = ["tank", "damage", "support", "open"]
        return roleDict
            .map { RoleWithStats(key: $0.key, stats: $0.value) }
            .sorted { a, b in
                let ia = order.firstIndex(of: a.key) ?? 99
                let ib = order.firstIndex(of: b.key) ?? 99
                return ia < ib
            }
    }

    // MARK: - Radar Chart Data
    var selectedRadarRole: String? = nil // nil = all, "tank", "damage", "support"

    struct RadarDataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double // 0-1 normalized
    }

    // Role-specific benchmarks (approximate community medians per 10 min)
    // These represent typical Gold-Platinum level averages
    private static let roleBenchmarks: [String?: (elims: Double, assists: Double, deaths: Double, damage: Double, healing: Double)] = [
        nil:        (elims: 14.0, assists: 4.0,  deaths: 6.5, damage: 6000,  healing: 2500),
        "tank":     (elims: 16.0, assists: 3.0,  deaths: 5.5, damage: 8000,  healing: 500),
        "damage":   (elims: 18.0, assists: 1.0,  deaths: 7.0, damage: 8500,  healing: 200),
        "support":  (elims: 10.0, assists: 7.0,  deaths: 6.0, damage: 3500,  healing: 6000),
    ]

    // Max scale values per role (top-tier performance ceiling)
    private static let roleMaxValues: [String?: (elims: Double, assists: Double, deaths: Double, damage: Double, healing: Double)] = [
        nil:        (elims: 28.0, assists: 15.0, deaths: 15.0, damage: 12000, healing: 8000),
        "tank":     (elims: 28.0, assists: 10.0, deaths: 15.0, damage: 14000, healing: 3000),
        "damage":   (elims: 30.0, assists: 6.0,  deaths: 15.0, damage: 14000, healing: 2000),
        "support":  (elims: 18.0, assists: 15.0, deaths: 15.0, damage: 6000,  healing: 10000),
    ]

    func radarData(for role: String?) -> [RadarDataPoint] {
        let avg: StatAverages?
        let deaths: Double

        if let role = role, let roleEntry = statsSummary?.roles?[role] {
            avg = roleEntry.average
            deaths = roleEntry.average?.deaths ?? 0
        } else {
            avg = statsSummary?.general?.average
            deaths = deathsPer10
        }

        let elims = avg?.eliminations ?? 0
        let assists = avg?.assists ?? 0
        let damage = avg?.damage ?? 0
        let healing = avg?.healing ?? 0

        let maxVals = Self.roleMaxValues[role] ?? Self.roleMaxValues[nil]!
        let survivability = max(0, 1.0 - (deaths / maxVals.deaths))

        return [
            RadarDataPoint(label: "Elims", value: min(1, elims / maxVals.elims)),
            RadarDataPoint(label: "Assists", value: min(1, assists / maxVals.assists)),
            RadarDataPoint(label: "Survival", value: min(1, survivability)),
            RadarDataPoint(label: "Damage", value: min(1, damage / maxVals.damage)),
            RadarDataPoint(label: "Healing", value: min(1, healing / maxVals.healing)),
        ]
    }

    func radarMedianData(for role: String?) -> [RadarDataPoint] {
        let bench = Self.roleBenchmarks[role] ?? Self.roleBenchmarks[nil]!
        let maxVals = Self.roleMaxValues[role] ?? Self.roleMaxValues[nil]!
        let medianSurvival = max(0, 1.0 - (bench.deaths / maxVals.deaths))

        return [
            RadarDataPoint(label: "Elims", value: min(1, bench.elims / maxVals.elims)),
            RadarDataPoint(label: "Assists", value: min(1, bench.assists / maxVals.assists)),
            RadarDataPoint(label: "Survival", value: min(1, medianSurvival)),
            RadarDataPoint(label: "Damage", value: min(1, bench.damage / maxVals.damage)),
            RadarDataPoint(label: "Healing", value: min(1, bench.healing / maxVals.healing)),
        ]
    }
}
