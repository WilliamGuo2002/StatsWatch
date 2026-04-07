import SwiftUI

struct SearchView: View {
    @Bindable var viewModel: PlayerViewModel
    @State private var navigationPath = NavigationPath()
    @State private var favorites: [FavoritePlayer] = []
    @State private var history: [SearchHistoryItem] = []
    @State private var showLanguagePicker = false
    @AppStorage("app_language") private var appLanguage: String = ""

    private let storage = LocalStorageService.shared

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("StatsWatch")
                                .font(.system(size: 28, weight: .bold))

                            Text("Overwatch Stats Tracker")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 30)

                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)

                            TextField("BattleTag or Name (e.g. Player#1234)", text: $viewModel.searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit {
                                    Task {
                                        await viewModel.searchPlayers()
                                        autoNavigateIfDirectLookup()
                                    }
                                }

                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.searchText = ""
                                    viewModel.searchResults = []
                                    viewModel.searchError = nil
                                    viewModel.directLookupPlayerId = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        // Search button
                        Button {
                            Task {
                                await viewModel.searchPlayers()
                                autoNavigateIfDirectLookup()
                            }
                        } label: {
                            HStack {
                                if viewModel.isSearching {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Search")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel.searchText.isEmpty || viewModel.isSearching)
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // Error message
                        if let error = viewModel.searchError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.top, 8)
                        }

                        // Search results
                        if !viewModel.searchResults.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(viewModel.searchResults) { player in
                                    Button {
                                        navigationPath.append(player.playerId)
                                    } label: {
                                        PlayerSearchRow(player: player)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 12)
                        }

                        // Favorites & History (when no search results)
                        if viewModel.searchResults.isEmpty && viewModel.searchError == nil {
                            // Quick links
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                            ], spacing: 10) {
                                NavigationLink {
                                    HeroMetaView(viewModel: viewModel)
                                } label: {
                                    QuickLinkCard(icon: "chart.bar.fill", title: "Hero Meta", color: .purple)
                                }
                                NavigationLink {
                                    HeroEncyclopediaListView(viewModel: viewModel)
                                } label: {
                                    QuickLinkCard(icon: "book.fill", title: "Encyclopedia", color: .cyan)
                                }
                                NavigationLink {
                                    PlayerComparisonView()
                                } label: {
                                    QuickLinkCard(icon: "person.2.fill", title: "PvP Compare", color: .red)
                                }
                                NavigationLink {
                                    MapGalleryView()
                                } label: {
                                    QuickLinkCard(icon: "map.fill", title: "Maps", color: .green)
                                }
                                NavigationLink {
                                    GamemodesView()
                                } label: {
                                    QuickLinkCard(icon: "gamecontroller.fill", title: "Game Modes", color: .orange)
                                }
                                NavigationLink {
                                    FeedbackTipView()
                                } label: {
                                    QuickLinkCard(icon: "heart.circle.fill", title: "Feedback & Tip", color: .pink)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                            .padding(.top, 16)

                            // Favorites
                            if !favorites.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.orange)
                                        Text("Favorites")
                                            .font(.system(size: 16, weight: .bold))
                                        Spacer()
                                    }

                                    ForEach(favorites) { fav in
                                        Button {
                                            navigationPath.append(fav.playerId)
                                        } label: {
                                            FavoritePlayerRow(player: fav)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 16)
                            }

                            // Search History
                            if !history.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundStyle(.secondary)
                                        Text("Recent")
                                            .font(.system(size: 16, weight: .bold))
                                        Spacer()
                                        Button("Clear") {
                                            storage.clearHistory()
                                            history = []
                                        }
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    }

                                    ForEach(history) { item in
                                        Button {
                                            navigationPath.append(item.playerId)
                                        } label: {
                                            HistoryRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                            }

                            // Tips
                            VStack(spacing: 12) {
                                Divider()
                                    .padding(.vertical, 8)

                                Text("Tip: Enter the full BattleTag (Name#1234) for direct lookup")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)

                                Text("Note: BattleTag is **case-sensitive**")
                                    .font(.footnote)
                                    .foregroundStyle(.orange)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }

                        // Disclaimer
                        VStack(spacing: 6) {
                            Divider()
                                .padding(.top, 16)

                            Text("This app is not affiliated with or endorsed by Blizzard Entertainment. Overwatch and all related assets are trademarks of Blizzard Entertainment, Inc. Data provided by OverFast API.")
                                .font(.system(size: 9))
                                .foregroundStyle(.quaternary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationDestination(for: String.self) { playerId in
                PlayerProfileView(viewModel: viewModel, playerId: playerId)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLanguagePicker = true
                    } label: {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerSheet(selectedLanguage: $appLanguage)
            }
            .onAppear {
                favorites = storage.getFavorites()
                history = storage.getHistory()
            }
        }
    }

    private func autoNavigateIfDirectLookup() {
        if let playerId = viewModel.directLookupPlayerId {
            navigationPath.append(playerId)
            viewModel.directLookupPlayerId = nil
        }
    }
}

struct QuickLinkCard: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FavoritePlayerRow: View {
    let player: FavoritePlayer

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: URL(string: player.avatar ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.15))
                    .overlay { Image(systemName: "person.fill").foregroundStyle(.secondary) }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            Text(player.name)
                .font(.system(size: 14, weight: .medium))

            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HistoryRow: View {
    let item: SearchHistoryItem

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: URL(string: item.avatar ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.15))
                    .overlay { Image(systemName: "person.fill").foregroundStyle(.secondary).font(.system(size: 10)) }
            }
            .frame(width: 30, height: 30)
            .clipShape(Circle())

            Text(item.name)
                .font(.system(size: 13))

            Spacer()

            Text(item.searchedAt, style: .relative)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}

struct PlayerSearchRow: View {
    let player: PlayerSearchResult

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: player.avatar ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(formatBattleTag(from: player.playerId))
                    .font(.system(size: 16, weight: .semibold))

                if player.isPublic == false {
                    Label("Private Profile", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("Public Profile")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Language Picker
struct LanguagePickerSheet: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss

    private let languages: [(code: String, flag: String, name: String, localName: String)] = [
        ("",       "🌐", "System Default", "跟随系统"),
        ("en",     "🇺🇸", "English", "English"),
        ("zh-Hans","🇨🇳", "Chinese (Simplified)", "简体中文"),
        ("ko",     "🇰🇷", "Korean", "한국어"),
        ("ja",     "🇯🇵", "Japanese", "日本語"),
        ("es",     "🇪🇸", "Spanish", "Español"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(languages, id: \.code) { lang in
                    Button {
                        selectedLanguage = lang.code
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(lang.flag)
                                .font(.system(size: 28))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.localName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(lang.name)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedLanguage == lang.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
