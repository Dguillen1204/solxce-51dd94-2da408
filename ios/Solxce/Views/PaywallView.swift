// Views/PaywallView.swift
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subManager = SubscriptionManager.shared
    @State private var trialEnabled: Bool = true
    @State private var showingCloseButton: Bool = false
    @State private var isShowingLegalSheet: Bool = false
    @State private var selectedLegalDoc: LegalDocumentView.DocumentType = .privacy

    var onUnlocked: (() -> Void)? = nil

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

                        // 7-Day Free Trial Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable 7-Day Free Trial")
                                    .font(AppTheme.headlineFont)
                                    .foregroundStyle(AppTheme.text)
                                Text("Cancel anytime before trial ends without being charged")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $trialEnabled)
                                .labelsHidden()
                                .tint(AppTheme.primary)
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                .strokeBorder(AppTheme.hairline)
                        )

                        // CTA and Microcopy
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text(trialEnabled ? "7 days free, then \(subManager.selectedPlan.billedAmount)" : "Billed as \(subManager.selectedPlan.billedAmount)")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textMuted)

                            Button {
                                Task {
                                    await subManager.purchase(plan: subManager.selectedPlan)
                                    onUnlocked?()
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    if subManager.isPurchasing {
                                        ProgressView()
                                            .tint(AppTheme.onPrimary)
                                    } else {
                                        Text(trialEnabled ? "Start 7-Day Free Trial" : "Unlock Solxce Pro")
                                            .font(AppTheme.headlineFont)
                                            .bold()
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .foregroundStyle(AppTheme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(AppTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            }
                            .disabled(subManager.isPurchasing)

                            Text("No commitment • Cancel anytime in Apple ID Settings")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textMuted)
                        }

                        // Footer Actions
                        HStack(spacing: AppTheme.Spacing.lg) {
                            Button("Restore Purchases") {
                                Task {
                                    let success = await subManager.restorePurchases()
                                    if success {
                                        onUnlocked?()
                                        dismiss()
                                    }
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)

                            Text("•").foregroundStyle(AppTheme.textMuted)

                            Button("Terms of Use") {
                                selectedLegalDoc = .terms
                                isShowingLegalSheet = true
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)

                            Text("•").foregroundStyle(AppTheme.textMuted)

                            Button("Privacy Policy") {
                                selectedLegalDoc = .privacy
                                isShowingLegalSheet = true
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.top, AppTheme.Spacing.xs)
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)
                }
            }
        }
        .sheet(isPresented: $isShowingLegalSheet) {
            LegalDocumentView(selectedDoc: selectedLegalDoc)
        }
        .onAppear {
            // Safe delayed close button reveal for App Review best-practice
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingCloseButton = true
                }
            }
        }
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
