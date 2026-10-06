// Views/PrivacyRulesSettingsView.swift
import SwiftUI

public struct PrivacyRulesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var relationshipStore = SocialRelationshipStore.shared

    @State private var showingUnblockConfirmation: String? = nil
    @State private var successToast = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Privacy Header Shield
                    privacyHeaderCard

                    // Profile Visibility
                    profileVisibilitySection

                    // Direct Messaging Rules
                    directMessageRulesSection

                    // Activity & Metric Privacy
                    activityPrivacySection

                    // Blocked Accounts Management
                    blockedAccountsSection
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Privacy & Safety Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .alert(
                "Unblock @\(showingUnblockConfirmation ?? "")?",
                isPresented: Binding(
                    get: { showingUnblockConfirmation != nil },
                    set: { if !$0 { showingUnblockConfirmation = nil } }
                )
            ) {
                Button("Unblock", role: .none) {
                    if let handle = showingUnblockConfirmation {
                        relationshipStore.unblock(handle: handle)
                        triggerToast()
                    }
                    showingUnblockConfirmation = nil
                }
                Button("Cancel", role: .cancel) {
                    showingUnblockConfirmation = nil
                }
            } message: {
                Text("They will now be able to view your profile and see your feed workouts.")
            }
            .overlay(alignment: .bottom) {
                if successToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.primary)
                        Text("Privacy settings saved")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.primary.opacity(0.3), lineWidth: 1))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Header
    private var privacyHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Athlete Privacy Standard")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)

                Text("Control your profile visibility, who can message you, and what telemetry is shared.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
    }

    // MARK: - Profile Visibility
    private var profileVisibilitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("PROFILE VISIBILITY")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 0) {
                ForEach(ProfileVisibility.allCases) { visibility in
                    Button {
                        relationshipStore.profileVisibility = visibility
                        triggerToast()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(visibility.rawValue)
                                    .font(AppTheme.subheadlineFont)
                                    .foregroundStyle(AppTheme.text)

                                Text(visibility.description)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            if relationshipStore.profileVisibility == visibility {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.primary)
                            } else {
                                Circle()
                                    .stroke(AppTheme.hairline, lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    .buttonStyle(.plain)

                    if visibility != ProfileVisibility.allCases.last {
                        Divider().background(AppTheme.hairline).padding(.leading, 16)
                    }
                }
            }
            .background(AppTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        }
    }

    // MARK: - Direct Messaging Rules
    private var directMessageRulesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("WHO CAN MESSAGE YOU")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 0) {
                ForEach(MessagePermission.allCases) { perm in
                    Button {
                        relationshipStore.messagePermission = perm
                        triggerToast()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(perm.rawValue)
                                    .font(AppTheme.subheadlineFont)
                                    .foregroundStyle(AppTheme.text)

                                Text(perm.description)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            if relationshipStore.messagePermission == perm {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.primary)
                            } else {
                                Circle()
                                    .stroke(AppTheme.hairline, lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    .buttonStyle(.plain)

                    if perm != MessagePermission.allCases.last {
                        Divider().background(AppTheme.hairline).padding(.leading, 16)
                    }
                }
            }
            .background(AppTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        }
    }

    // MARK: - Activity & Metric Privacy
    private var activityPrivacySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("TELEMETRY & ACTIVITY PRIVACY")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 0) {
                Toggle(isOn: $relationshipStore.hideWorkoutSplits) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hide Mile Split Times")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.text)
                        Text("Hide per-mile pacing from public running posts")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .padding(AppTheme.Spacing.md)

                Divider().background(AppTheme.hairline).padding(.leading, 16)

                Toggle(isOn: $relationshipStore.hideBodyWeight) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hide Bodyweight Metrics")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.text)
                        Text("Do not include bodyweight in strength leaderboards")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .padding(AppTheme.Spacing.md)

                Divider().background(AppTheme.hairline).padding(.leading, 16)

                Toggle(isOn: $relationshipStore.showOnlineStatus) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show Online Activity Indicator")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.text)
                        Text("Allow followers to see when you are actively logging workouts")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.primary)
                .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        }
    }

    // MARK: - Blocked Accounts
    private var blockedAccountsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("BLOCKED ATHLETES (\(relationshipStore.blockedHandles.count))")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 0) {
                if relationshipStore.blockedHandles.isEmpty {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("No blocked athletes.")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                } else {
                    ForEach(Array(relationshipStore.blockedHandles), id: \.self) { handle in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("@\(handle)")
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("Blocked from messaging and viewing profile")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            Button {
                                showingUnblockConfirmation = handle
                            } label: {
                                Text("Unblock")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.primary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(AppTheme.Spacing.md)

                        if handle != Array(relationshipStore.blockedHandles).last {
                            Divider().background(AppTheme.hairline).padding(.leading, 16)
                        }
                    }
                }
            }
            .background(AppTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        }
    }

    private func triggerToast() {
        withAnimation {
            successToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                successToast = false
            }
        }
    }
}
