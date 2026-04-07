import Foundation

actor OverwatchAPIService {
    static let shared = OverwatchAPIService()
    private let baseURL = "https://overfast-api.tekrop.fr"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search Players
    func searchPlayers(name: String) async throws -> PlayerSearchResponse {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let url = URL(string: "\(baseURL)/players?name=\(encoded)&limit=20")!
        return try await fetch(url: url)
    }

    // MARK: - Player Summary
    func getPlayerSummary(playerId: String) async throws -> PlayerSummary {
        let url = URL(string: "\(baseURL)/players/\(playerId)/summary")!
        return try await fetch(url: url)
    }

    // MARK: - Player Stats Summary
    func getPlayerStatsSummary(playerId: String, gamemode: GameMode = .quickplay) async throws -> PlayerStatsSummary {
        let url = URL(string: "\(baseURL)/players/\(playerId)/stats/summary?gamemode=\(gamemode.rawValue)")!
        return try await fetch(url: url)
    }

    // MARK: - Heroes List
    func getHeroes() async throws -> [HeroInfo] {
        let url = URL(string: "\(baseURL)/heroes")!
        return try await fetch(url: url)
    }

    // MARK: - Hero Detail
    func getHeroDetail(heroKey: String) async throws -> HeroDetail {
        let url = URL(string: "\(baseURL)/heroes/\(heroKey)")!
        return try await fetch(url: url)
    }

    // MARK: - Hero Global Stats
    func getHeroGlobalStats(platform: String = "pc", gamemode: String = "competitive") async throws -> [HeroGlobalStat] {
        let url = URL(string: "\(baseURL)/heroes/stats?platform=\(platform)&gamemode=\(gamemode)")!
        return try await fetch(url: url)
    }

    // MARK: - Player Career Stats
    func getPlayerCareerStats(playerId: String, gamemode: GameMode = .competitive) async throws -> [String: [CareerStatCategory]] {
        let url = URL(string: "\(baseURL)/players/\(playerId)/stats/career?gamemode=\(gamemode.rawValue)")!
        return try await fetch(url: url)
    }

    // MARK: - Maps
    func getMaps() async throws -> [MapInfo] {
        let url = URL(string: "\(baseURL)/maps")!
        return try await fetch(url: url)
    }

    // MARK: - Gamemodes
    func getGamemodes() async throws -> [GamemodeInfo] {
        let url = URL(string: "\(baseURL)/gamemodes")!
        return try await fetch(url: url)
    }

    // MARK: - Generic Fetch
    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw APIError.playerNotFound
            }
            if httpResponse.statusCode == 422 {
                throw APIError.profilePrivate
            }
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case playerNotFound
    case profilePrivate
    case rateLimited
    case serverError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .playerNotFound:
            return "Player not found. Check the BattleTag and try again."
        case .profilePrivate:
            return "This player's profile is set to private."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError(let msg):
            return "Failed to parse data: \(msg)"
        }
    }
}
