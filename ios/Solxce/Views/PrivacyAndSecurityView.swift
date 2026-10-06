// Views/PrivacyAndSecurityView.swift
import SwiftUI

struct PrivacyAndSecurityView: View {
    @ObservedObject private var socialManager = SocialPrivacyManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingBlockedList = false
    @State private var showingDataSharingInfo = false

    var body: some View {
        NavigationStack {
            List {
                // Account Privacy Mode
                Section {
                    Toggle(isOn: $socialManager.isPrivateAccount) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Private Account")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.primary)
                            Text(socialManager.isPrivateAccount
                                 ? "Only approved followers can view your workouts, reels, and stats."
                                 : "Anyone on Solxce can discover your profile and public posts.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.accent)
                } header: {
                    Text("Account Visibility").foregroundStyle(AppTheme.textSecondary)
                } footer: {
                    Text("When your account is private, your workout logs remain hidden from the global public leaderboard.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Direct Messaging Rules
                Section {
                    Picker("Who can direct message you", selection: $socialManager.dmPermission) {
                        ForEach(DMReceivePermission.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)

                    Text(socialManager.dmPermission.description)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                } header: {
                    Text("Direct Messaging Rules").foregroundStyle(AppTheme.textSecondary)
                }

                // Post & Workout Default Visibility
                Section {
                    Picker("Default Post Visibility", selection: $socialManager.postVisibility) {
                        ForEach(PostVisibilityRule.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)

                    Toggle(isOn: $socialManager.shareWorkoutDataPublicly) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show Workout Metrics in Posts")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.primary)
                            Text("Include tonnage, miles, heart rate, and splits on public feed cards.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.accent)
                } header: {
                    Text("Feed & Performance Sharing").foregroundStyle(AppTheme.textSecondary)
                }

                // Interactions & Activity Status
                Section {
                    Toggle(isOn: $socialManager.showActivityStatus) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show Active Training Status")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.primary)
                            Text("Allow training partners to see when you are actively logging a workout.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.accent)

                    Toggle(isOn: $socialManager.allowTagging) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Allow Athlete Tags & Mentions")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.primary)
                            Text("Allow others to mention @your_handle in post captions and comments.")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.accent)
                } header: {
                    Text("Interactions").foregroundStyle(AppTheme.textSecondary)
                }

                // Blocked Accounts Management
                Section {
                    NavigationLink {
                        BlockedAccountsView()
                    } label: {
                        HStack {
                            Label("Blocked Accounts", systemImage: "hand.raised.fill")
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            Text("\(socialManager.blockedHandles.count)")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                } header: {
                    Text("Safety & Filtering").foregroundStyle(AppTheme.textSecondary)
                } footer: {
                    Text("Blocked athletes cannot message you, see your posts, or find your profile.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Privacy & Safety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Blocked Accounts Management View
struct BlockedAccountsView: View {
    @ObservedObject private var socialManager = SocialPrivacyManager.shared
    @State private var athleteToUnblock: String? = nil
    @State private var showingUnblockConfirmation = false

    private var blockedList: [String] {
        Array(socialManager.blockedHandles).sorted()
    }

    var body: some View {
        List {
            if blockedList.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.top, 24)

                    Text("No Blocked Accounts")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.primary)

                    Text("Athletes you block will appear here. You can unblock them at any time.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(AppTheme.surface)
            } else {
                ForEach(blockedList, id: \.self) { handle in
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: "#FF3B5C"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(handle)")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.primary)
                            Text("Blocked")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(Color(hex: "#FF3B5C"))
                        }

                        Spacer()

                        Button {
                            athleteToUnblock = handle
                            showingUnblockConfirmation = true
                        } label: {
                            Text("Unblock")
                                .font(AppTheme.captionFont.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(AppTheme.surfaceElevated)
                                .clipShape(Capsule())
                        }
                    }
                    .listRowBackground(AppTheme.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.ground.ignoresSafeArea())
        .navigationTitle("Blocked Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Unblock @\(athleteToUnblock ?? "")?",
            isPresented: $showingUnblockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unblock Athlete", role: .destructive) {
                if let handle = athleteToUnblock {
                    withAnimation {
                        socialManager.unblockUser(handle: handle)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will once again be able to view your public posts and request to message you.")
        }
    }
}
