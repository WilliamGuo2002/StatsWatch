import SwiftUI

struct MapGalleryView: View {
    @State private var maps: [MapInfo] = []
    @State private var gamemodes: [GamemodeInfo] = []
    @State private var isLoading = true
    @State private var selectedGamemode: String? = nil

    private let api = OverwatchAPIService.shared

    private var filteredMaps: [MapInfo] {
        guard let gm = selectedGamemode else { return maps }
        return maps.filter { $0.gamemodes?.contains(gm) == true }
    }

    private var allGamemodes: [String] {
        var set = Set<String>()
        for map in maps {
            for gm in map.gamemodes ?? [] {
                set.insert(gm)
            }
        }
        return set.sorted()
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else {
                VStack(spacing: 14) {
                    // Gamemode filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: selectedGamemode == nil) {
                                selectedGamemode = nil
                            }
                            ForEach(allGamemodes, id: \.self) { gm in
                                let info = gamemodes.first { $0.key == gm }
                                FilterChip(
                                    label: info?.name ?? gm.capitalized,
                                    isSelected: selectedGamemode == gm
                                ) {
                                    selectedGamemode = gm
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Text("\(filteredMaps.count) Maps")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Map grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ], spacing: 10) {
                        ForEach(filteredMaps) { map in
                            MapCard(map: map, gamemodes: gamemodes)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Maps")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let mapsTask = api.getMaps()
            async let modesTask = api.getGamemodes()
            do {
                maps = try await mapsTask
                gamemodes = try await modesTask
            } catch {}
            isLoading = false
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .clipShape(Capsule())
        }
    }
}

struct MapCard: View {
    let map: MapInfo
    let gamemodes: [GamemodeInfo]
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Screenshot
                if let url = map.screenshot.flatMap({ URL(string: $0) }) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay {
                                Image(systemName: "map")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.tertiary)
                            }
                    }
                    .frame(height: 90)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 90)
                        .overlay {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .foregroundStyle(.tertiary)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(map.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    if let location = map.location {
                        HStack(spacing: 3) {
                            if let code = map.countryCode {
                                Text(flag(from: code))
                                    .font(.system(size: 10))
                            }
                            Text(location)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Gamemode tags
                    if let gms = map.gamemodes, !gms.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(gms.prefix(2), id: \.self) { gm in
                                let name = gamemodes.first { $0.key == gm }?.name ?? gm.capitalized
                                Text(name)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            if gms.count > 2 {
                                Text("+\(gms.count - 2)")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(8)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            MapDetailSheet(map: map, gamemodes: gamemodes)
        }
    }

    private func flag(from countryCode: String) -> String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}

// MARK: - Map Detail Sheet
struct MapDetailSheet: View {
    let map: MapInfo
    let gamemodes: [GamemodeInfo]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Large screenshot
                    if let url = map.screenshot.flatMap({ URL(string: $0) }) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                        }
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Info
                    VStack(spacing: 12) {
                        if let location = map.location {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.red)
                                Text(location)
                                    .font(.system(size: 15))
                                if let code = map.countryCode {
                                    Text(flag(from: code))
                                        .font(.system(size: 18))
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                        }

                        // Gamemodes
                        if let gms = map.gamemodes, !gms.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Game Modes")
                                    .font(.system(size: 14, weight: .bold))

                                ForEach(gms, id: \.self) { gm in
                                    if let info = gamemodes.first(where: { $0.key == gm }) {
                                        GamemodeRow(gamemode: info)
                                    } else {
                                        Text(gm.capitalized)
                                            .font(.system(size: 13))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(map.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func flag(from countryCode: String) -> String {
        let base: UInt32 = 127397
        return countryCode.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}
