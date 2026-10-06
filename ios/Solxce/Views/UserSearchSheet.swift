// Views/UserSearchSheet.swift
import SwiftUI

public struct UserSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var postStore = FeedPostStore.shared
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared
    
    let currentUserHandle: String
    let onSelectAthlete: (String, String, AthleteType) -> Void

    @State private var query: String = ""
    @State private var selectedFilter: AthleteType? = nil

    public init(
        currentUserHandle: String = "solxce_athlete",
        onSelectAthlete: @escaping (String, String, AthleteType) -> Void
    ) {
        self.currentUserHandle = currentUserHandle
        self.onSelectAthlete = onSelectAthlete
    }

    // Curated discoverable athletes from Feed posts and relationship store
    private var allAthletes: [DiscoveredAthlete] {
        var map: [String: DiscoveredAthlete] = [:]

        // Add standard community athletes
        let presetAthletes: [DiscoveredAthlete] = [
            DiscoveredAthlete(handle: "marcus_vance", name: "Marcus Vance", type: .hybrid, bio: "HYROX Pro & Strength Specialist • Fueling clean", followersCount: 1420),
            DiscoveredAthlete(handle: "elena_sol", name: "Elena Rostova", type: .runner, bio: "Sub-3 Marathoner • Ultra trail runner", followersCount: 2890),
            DiscoveredAthlete(handle: "kai_nordic", name: "Kai Lindqvist", type: .swimmer, bio: "Open water distance swimmer & triathlete", followersCount: 950),
            DiscoveredAthlete(handle: "tariq_lift", name: "Tariq Al-Mansoor", type: .bodybuilder, bio: "Classic physique athlete & powerlifter", followersCount: 3120),
            DiscoveredAthlete(handle: "chloe_cycle", name: "Chloe Bennett", type: .cyclist, bio: "Gravel endurance cyclist • Wattage junkie", followersCount: 1680),
            DiscoveredAthlete(handle: "alex_cross", name: "Alex Chen", type: .crossfit, bio: "CrossFit Games Open Competitor", followersCount: 2150)
        ]

        for athlete in presetAthletes {
            map[athlete.handle] = athlete
        }

        // Add distinct authors from feed posts
        for post in postStore.posts {
            let handle = post.authorHandle
            if handle != currentUserHandle && !relationshipStore.isBlocked(handle: handle) {
                if map[handle] == nil {
                    map[handle] = DiscoveredAthlete(
                        handle: handle,
                        name: post.authorName,
                        type: post.athleteType,
                        bio: "Solxce community athlete",
                        followersCount: 840
                    )
                }
            }
        }

        return Array(map.values).sorted { $0.followersCount > $1.followersCount }
    }

    private var filteredAthletes: [DiscoveredAthlete] {
        let list = allAthletes.filter { athlete in
            guard !relationshipStore.isBlocked(handle: athlete.handle) else { return false }
            
            if let filter = selectedFilter, athlete.type != filter {
                return false
            }

            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }

            let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            return athlete.name.localizedCaseInsensitiveContains(q) ||
                   athlete.handle.localizedCaseInsensitiveContains(q) ||
                   athlete.bio.localizedCaseInsensitiveContains(q)
        }
        return list
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input
                searchBarSection

                // Discipline Filter Chips
                filterChipRail

                // Athlete Results List
                if filteredAthletes.isEmpty {
                    emptySearchResultsView
                } else {
                    List {
                        ForEach(filteredAthletes) { athlete in
                            Button {
                                dismiss()
                                onSelectAthlete(athlete.handle, athlete.name, athlete.type)
                            } label: {
                                DiscoveredAthleteRow(
                                    athlete: athlete,
                                    isFollowing: relationshipStore.isFollowing(handle: athlete.handle),
                                    onToggleFollow: {
                                        relationshipStore.toggleFollow(handle: athlete.handle)
                                    }
                                )
                            }
                            .listRowBackground(AppTheme.ground)
                            .listRowSeparatorTint(AppTheme.hairline)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Find Athletes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textSecondary)
                .font(.system(size: 15, weight: .semibold))

            TextField("Search by name, @handle, or discipline...", text: $query)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Discipline Chips
    private var filterChipRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Chip
                Button {
                    selectedFilter = nil
                } label: {
                    Text("All Athletes")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedFilter == nil ? AppTheme.primary : AppTheme.surface)
                        .foregroundColor(selectedFilter == nil ? AppTheme.onPrimary : AppTheme.textSecondary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedFilter == nil ? Color.clear : AppTheme.hairline, lineWidth: 1))
                }

                ForEach(AthleteType.allCases, id: \.self) { type in
                    Button {
                        selectedFilter = (selectedFilter == type) ? nil : type
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 10, weight: .bold))
                            Text(type.displayName)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedFilter == type ? AppTheme.primary : AppTheme.surface)
                        .foregroundColor(selectedFilter == type ? AppTheme.onPrimary : AppTheme.textSecondary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedFilter == type ? Color.clear : AppTheme.hairline, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Empty State
    private var emptySearchResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 72, height: 72)
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            VStack(spacing: 6) {
                Text("No Athletes Found")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.text)
                Text("Try searching with a different name, handle, or sport filter.")
                    .font(AppTheme.subheadlineFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }
}

// MARK: - Discovered Athlete Model
public struct DiscoveredAthlete: Identifiable {
    public var id: String { handle }
    public let handle: String
    public let name: String
    public let type: AthleteType
    public let bio: String
    public let followersCount: Int
}

// MARK: - Discovered Athlete Row
public struct DiscoveredAthleteRow: View {
    let athlete: DiscoveredAthlete
    let isFollowing: Bool
    let onToggleFollow: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            // Monogram / Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.8), AppTheme.accent.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Text(athlete.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(AppTheme.onPrimary)
            }

            // Athlete Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(athlete.name)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.text)

                    HStack(spacing: 3) {
                        Image(systemName: athlete.type.iconName)
                            .font(.system(size: 8, weight: .bold))
                        Text(athlete.type.displayName.uppercased())
                            .font(.system(size: 8, weight: .black))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(AppTheme.surfaceRaised)
                    .foregroundColor(AppTheme.primary)
                    .clipShape(Capsule())
                }

                Text("@\(athlete.handle)")
                    .font(AppTheme.monoFont)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)

                Text(athlete.bio)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            // Follow Button
            Button {
                onToggleFollow()
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isFollowing ? AppTheme.textSecondary : AppTheme.onPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(isFollowing ? AppTheme.surfaceRaised : AppTheme.primary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isFollowing ? AppTheme.hairline : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
