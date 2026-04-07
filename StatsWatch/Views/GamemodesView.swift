import SwiftUI

struct GamemodesView: View {
    @State private var gamemodes: [GamemodeInfo] = []
    @State private var isLoading = true

    private let api = OverwatchAPIService.shared

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 60)
            } else {
                VStack(spacing: 12) {
                    ForEach(gamemodes) { mode in
                        GamemodeCard(gamemode: mode)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Game Modes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                gamemodes = try await api.getGamemodes()
            } catch {}
            isLoading = false
        }
    }
}

struct GamemodeCard: View {
    let gamemode: GamemodeInfo
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Screenshot header
            if let url = gamemode.screenshot.flatMap({ URL(string: $0) }) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                }
                .frame(height: 120)
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 8) {
                        if let icon = gamemode.icon.flatMap({ URL(string: $0) }) {
                            AsyncImage(url: icon) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                EmptyView()
                            }
                            .frame(width: 24, height: 24)
                        }

                        Text(gamemode.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                    }
                    .padding(12)
                }
            } else {
                HStack(spacing: 8) {
                    if let icon = gamemode.icon.flatMap({ URL(string: $0) }) {
                        AsyncImage(url: icon) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            EmptyView()
                        }
                        .frame(width: 24, height: 24)
                    }

                    Text(gamemode.name)
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(12)
            }

            // Description
            if let desc = gamemode.description, !desc.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)

                        if desc.count > 80 {
                            Text(isExpanded ? "Show Less" : "Read More")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct GamemodeRow: View {
    let gamemode: GamemodeInfo

    var body: some View {
        HStack(spacing: 10) {
            if let icon = gamemode.icon.flatMap({ URL(string: $0) }) {
                AsyncImage(url: icon) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(Color(.systemGray5)).frame(width: 28, height: 28)
                }
                .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(gamemode.name)
                    .font(.system(size: 13, weight: .semibold))
                if let desc = gamemode.description {
                    Text(desc)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
