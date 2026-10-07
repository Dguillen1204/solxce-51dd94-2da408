// Views/PaywallView.swift
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subManager = SubscriptionManager.shared
    @State private var trialEnabled: Bool = true
    @State private var showingCloseButton: Bool = true
    @State private var isShowingLegalSheet: Bool = false
    @State private var selectedLegalDoc: LegalDocumentView.DocumentType = .privacy
    @State private var showApplePaySuccessBanner: Bool = false

    var onUnlocked: (() -> Void)? = nil

    private var trialChargeDateString: String {
        let targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: targetDate)
    }

    var body: some View {
        ZStack {
            AppTheme.ground.ignoresSafeArea()

            // Subtle Volt ambient radial glow
            RadialGradient(
                colors: [AppTheme.primary.opacity(0.18), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Toolbar Dismiss
                HStack {
                    Spacer()
                    if showingCloseButton {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.xs)

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Brand Hero & Badge
                        VStack(spacing: AppTheme.Spacing.sm) {
                            SolxceLogoView(size: 56, showGlow: true)

                            HStack(spacing: 6) {
                                Text("SOLXCE PRO")
                                    .font(AppTheme.eyebrowFont)
                                    .tracking(2.0)
                                    .foregroundStyle(AppTheme.onPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())

                            Text("Unlock Elite Performance")
                                .font(AppTheme.displayFont)
                                .foregroundStyle(AppTheme.text)
                                .multilineTextAlignment(.center)

                            Text("Log food at lightning speed with AI camera, master intermittent fasting with smart alerts, and unlock deep training analytics.")
                                .font(AppTheme.subheadlineFont)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        // Feature Rows
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(ProFeature.allCases, id: \.self) { feature in
                                featureRow(feature)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.sm)

                        // Plan Selector Cards
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(SubscriptionPlanTier.allCases) { plan in
                                planCard(plan)
                            }
                        }

                        // 7-Day Free Trial & Explicit Billing Schedule
                        trialTimelineCard

                        // Primary Action Button
                        primaryCtaSection

                        // Terms & Restore footer
                        footerLegalRow
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
        }
        .sheet(isPresented: $isShowingLegalSheet) {
            LegalDocumentView(documentType: selectedLegalDoc)
        }
    }

    private var trialTimelineCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .foregroundStyle(AppTheme.primary)
                Text("Risk-Free 7-Day Free Trial")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Toggle("", isOn: $trialEnabled)
                    .labelsHidden()
                    .tint(AppTheme.primary)
            }

            Divider().background(AppTheme.hairline)

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(AppTheme.hairline)
                        .frame(width: 2, height: 28)
                    Circle()
                        .fill(AppTheme.textMuted)
                        .frame(width: 8, height: 8)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textMuted)
                        Text("Instant access to all Pro features for 7 days at $0.00.")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.text)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day 7 (\(trialChargeDateString))")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textMuted)
                        Text("Trial ends. Subscription renews at \(subManager.selectedPlan.postTrialChargeText) unless cancelled.")
                            .font(AppTheme.subheadlineFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private var primaryCtaSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    _ = await subManager.unlockProWithTrial()
                    onUnlocked?()
                    dismiss()
                }
            } label: {
                HStack {
                    if subManager.isPurchasing {
                        ProgressView()
                            .tint(AppTheme.onPrimary)
                    } else {
                        Text(trialEnabled ? "Start 7-Day Free Trial" : "Subscribe Now")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.onPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
            }
            .buttonStyle(.plain)

            Text("Cancel anytime in Settings > Subscriptions at least 24h before renewal.")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var footerLegalRow: some View {
        HStack(spacing: 16) {
            Button("Privacy Policy") {
                selectedLegalDoc = .privacy
                isShowingLegalSheet = true
            }
            Text("•")
                .foregroundStyle(AppTheme.textMuted)
            Button("Terms of Use") {
                selectedLegalDoc = .terms
                isShowingLegalSheet = true
            }
            Text("•")
                .foregroundStyle(AppTheme.textMuted)
            Button("Restore") {
                Task {
                    _ = await subManager.restorePurchases()
                    dismiss()
                }
            }
        }
        .font(AppTheme.captionFont)
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.top, 4)
    }

    private func featureRow(_ feature: ProFeature) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.text)
                Text(feature.description)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
    }

    private func planCard(_ plan: SubscriptionPlanTier) -> some View {
        let isSelected = subManager.selectedPlan == plan

        return Button {
            subManager.selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)

                        if let badge = plan.savingsBadge {
                            Text(badge)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(AppTheme.onPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }

                    Text(plan.billedAmount)
                        .font(AppTheme.subheadlineFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? AppTheme.primary : AppTheme.textMuted, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .strokeBorder(isSelected ? AppTheme.primary : AppTheme.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
