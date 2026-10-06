// Views/PaywallView.swift
import SwiftUI
import PassKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subManager = SubscriptionManager.shared
    @State private var trialEnabled: Bool = true
    @State private var showingCloseButton: Bool = false
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

                        // MARK: - 7-Day Free Trial & Explicit Billing Schedule
                        trialTimelineCard

                        // MARK: - Apple Pay & Standard Checkout CTAs
                        VStack(spacing: AppTheme.Spacing.sm) {
                            // Primary Apple Pay CTA Button
                            Button {
                                Task {
                                    let success = await subManager.startTrialWithApplePay(plan: subManager.selectedPlan)
                                    if success {
                                        showApplePaySuccessBanner = true
                                        try? await Task.sleep(nanoseconds: 600_000_000)
                                        onUnlocked?()
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    if subManager.isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Set up with")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)

                                        HStack(spacing: 2) {
                                            Image(systemName: "apple.logo")
                                                .font(.system(size: 17, weight: .bold))
                                            Text("Pay")
                                                .font(.system(size: 17, weight: .bold))
                                        }
                                        .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radii.button)
                                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .disabled(subManager.isPurchasing)

                            // Secondary Standard CTA (Credit Card / App Store)
                            Button {
                                Task {
                                    await subManager.purchase(
                                        plan: subManager.selectedPlan,
                                        withTrial: trialEnabled,
                                        method: .creditCard
                                    )
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
                                            .bold()
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .foregroundStyle(AppTheme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            }
                            .disabled(subManager.isPurchasing)

                            // Transparent billing notice
                            Text("Auto-renews at \(subManager.selectedPlan.billedAmount) on \(trialChargeDateString). Cancel anytime before then in Apple ID Settings with zero charge.")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.Spacing.sm)
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

    // MARK: - 7-Day Trial Timeline Card
    private var trialTimelineCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.checkmark.fill")
                        .foregroundStyle(AppTheme.primary)
                    Text("7-DAY FREE TRIAL GUARANTEE")
                        .font(AppTheme.eyebrowFont)
                        .tracking(1.0)
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                Toggle("", isOn: $trialEnabled)
                    .labelsHidden()
                    .tint(AppTheme.primary)
            }

            if trialEnabled {
                VStack(spacing: 12) {
                    // Timeline step 1: Today
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AppTheme.onPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Today: Instant Full Access")
                                    .font(AppTheme.captionFont.weight(.bold))
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                Text("$0.00")
                                    .font(AppTheme.captionFont.weight(.bold))
                                    .foregroundStyle(AppTheme.primary)
                            }
                            Text("Unlock AI food scanning, fasting alerts, unlimited coaching & analytics immediately.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    // Vertical connector
                    HStack {
                        Rectangle()
                            .fill(AppTheme.primary.opacity(0.4))
                            .frame(width: 2, height: 16)
                            .padding(.leading, 10)
                        Spacer()
                    }

                    // Timeline step 2: Day 5 Reminder
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.surfaceRaised)
                                .frame(width: 22, height: 22)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Day 5: Trial Reminder Notification")
                                .font(AppTheme.captionFont.weight(.bold))
                                .foregroundStyle(AppTheme.text)
                            Text("We will notify you 2 days before the trial ends so you can cancel if Solxce is not for you.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    // Vertical connector
                    HStack {
                        Rectangle()
                            .fill(AppTheme.primary.opacity(0.4))
                            .frame(width: 2, height: 16)
                            .padding(.leading, 10)
                        Spacer()
                    }

                    // Timeline step 3: Day 7 Charging
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.surfaceRaised)
                                .frame(width: 22, height: 22)
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Day 7 (\(trialChargeDateString)): Auto-Charge")
                                    .font(AppTheme.captionFont.weight(.bold))
                                    .foregroundStyle(AppTheme.text)
                                Spacer()
                                Text(subManager.selectedPlan.postTrialChargeText)
                                    .font(AppTheme.captionFont.weight(.bold))
                                    .foregroundStyle(AppTheme.text)
                            }
                            Text("Your Apple Pay / payment card will be charged immediately after the 7-day trial ends unless cancelled before.")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .strokeBorder(AppTheme.hairline)
        )
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
