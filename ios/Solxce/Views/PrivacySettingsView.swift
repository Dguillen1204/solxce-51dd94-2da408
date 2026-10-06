// Views/PrivacySettingsView.swift
import SwiftUI

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    @State private var showingBlockedListSheet: Bool = false
    @State private var showSavedToast: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Section: Account Privacy
                Section {
                    Toggle(isOn: $relationshipStore.privacyRules.isPrivateAccount) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Private Account")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("When private, only approved followers can see your profile photos, videos, and workout feed.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(AppTheme.primary)
                } header: {
                    Text("ACCOUNT VISIBILITY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .listRowBackground(Color.white.opacity(0.04))

                // Section: Direct Messages & Interactions
                Section {
                    Picker(selection: $relationshipStore.privacyRules.allowDirectMessagesFrom) {
                        ForEach(UserPrivacyRules.DirectMessagePermission.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Direct Messages")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text(relationshipStore.privacyRules.allowDirectMessagesFrom.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Picker("Mentions & Tags", selection: $relationshipStore.privacyRules.allowTaggingAndMentions) {
                        ForEach(UserPrivacyRules.TaggingPermission.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } header: {
                    Text("MESSAGING & MENTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .listRowBackground(Color.white.opacity(0.04))

                // Section: Activity & Workout Metrics Sharing
                Section {
                    Toggle(isOn: $relationshipStore.privacyRules.showActivityStatus) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show Activity Status")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Allow athletes you follow to see when you are actively logging a workout.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(AppTheme.primary)

                    Toggle(isOn: $relationshipStore.privacyRules.showLifetimeVolumePublicly) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Public Lifetime Volume")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Display your cumulative tonnage lifted on your public profile header.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(AppTheme.primary)

                    Toggle(isOn: $relationshipStore.privacyRules.showRunPacePublicly) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Public 5K Pace Benchmarks")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Show verified mile and 5K split speeds on your athlete card.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(AppTheme.primary)
                } header: {
                    Text("WORKOUT METRICS & STATUS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .listRowBackground(Color.white.opacity(0.04))

                // Section: Safety & Blocked Accounts
                Section {
                    Toggle(isOn: $relationshipStore.privacyRules.filterOffensiveComments) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Filter Offensive Comments")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Automatically hide comments containing toxic words on your reels & posts.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .tint(AppTheme.primary)

                    Button {
                        showingBlockedListSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Blocked Accounts")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(relationshipStore.blockedHandles.count) blocked athletes")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                } header: {
                    Text("SAFETY & RESTRICTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .listRowBackground(Color.white.opacity(0.04))
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Privacy Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showingBlockedListSheet) {
                BlockedAccountsListView()
            }
        }
    }
}

// MARK: - Blocked Accounts List View
struct BlockedAccountsListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    private var blockedProfiles: [OtherAthleteProfile] {
        relationshipStore.blockedHandles.map { relationshipStore.getProfile(for: $0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if blockedProfiles.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.primary)

                        Text("No Blocked Athletes")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("Athletes you block will appear here. They won't be able to view your profile, posts, or message you.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(blockedProfiles) { profile in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: profile.avatarSymbol)
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("@\(profile.handle)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                Button {
                                    relationshipStore.unblockUser(handle: profile.handle)
                                } label: {
                                    Text("Unblock")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.04))
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Blocked Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}
