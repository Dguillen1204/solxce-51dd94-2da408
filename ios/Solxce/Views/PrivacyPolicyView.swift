// Views/PrivacyPolicyView.swift
import SwiftUI

/// Document viewer providing comprehensive, App Store compliant Privacy Policy and Terms of Service.
struct LegalDocumentView: View {
    enum DocumentType: String, CaseIterable, Identifiable {
        case privacy = "Privacy Policy"
        case terms = "Terms of Service"

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State var selectedDoc: DocumentType = .privacy

    // Public URL endpoints for Solxce
    static let privacyPolicyURL = "https://solxce.app/privacy"
    static let termsOfServiceURL = "https://solxce.app/terms"
    static let supportEmail = "support@solxce.app"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Document Switcher Picker
                Picker("Document", selection: $selectedDoc) {
                    ForEach(DocumentType.allCases) { doc in
                        Text(doc.rawValue).tag(doc)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.ground)

                Divider()
                    .overlay(AppTheme.hairline)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        // Header Badge & Last Updated
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedDoc == .privacy ? "hand.raised.shield.fill" : "doc.text.fill")
                                    .foregroundStyle(AppTheme.primary)
                                    .font(.system(size: 16, weight: .bold))
                                Text(selectedDoc.rawValue.uppercased())
                                    .font(AppTheme.eyebrowFont)
                                    .tracking(1.5)
                                    .foregroundStyle(AppTheme.primary)
                            }

                            Text(selectedDoc == .privacy ? "Solxce Athlete Privacy Policy" : "Solxce Terms of Service")
                                .font(AppTheme.titleFont)
                                .foregroundStyle(AppTheme.text)

                            HStack {
                                Text("Effective Date: March 2026")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)

                                Spacer()

                                Link(destination: URL(string: selectedDoc == .privacy ? LegalDocumentView.privacyPolicyURL : LegalDocumentView.termsOfServiceURL) ?? URL(string: "https://solxce.app")!) {
                                    HStack(spacing: 4) {
                                        Text("Open Web Page")
                                        Image(systemName: "arrow.up.right.square")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppTheme.primary)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                .stroke(AppTheme.hairline, lineWidth: 1)
                        )

                        // Content
                        if selectedDoc == .privacy {
                            privacyPolicySections
                        } else {
                            termsOfServiceSections
                        }

                        // Contact and Rights Footer
                        contactFooter
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle(selectedDoc.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.headlineFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                }
                ToolbarItem(placement: .cancellationAction) {
                    ShareLink(
                        item: URL(string: selectedDoc == .privacy ? LegalDocumentView.privacyPolicyURL : LegalDocumentView.termsOfServiceURL) ?? URL(string: "https://solxce.app")!,
                        subject: Text(selectedDoc == .privacy ? "Solxce Privacy Policy" : "Solxce Terms of Service"),
                        message: Text("Review the official legal policies for Solxce.")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Privacy Policy Sections
    private var privacyPolicySections: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            policySection(
                title: "1. Overview & Commitment to Athlete Privacy",
                content: """
                Solxce ("we", "our", or "us") is dedicated to protecting your privacy. This Privacy Policy explains what personal data we collect, why we collect it, how it is secured, and your rights when using the Solxce mobile app, backend sync services, and web portal.

                We do not sell, rent, or monetize your personal health, workout, camera, or nutrition data to third-party data brokers or advertising networks.
                """
            )

            policySection(
                title: "2. Information We Collect",
                content: """
                • Profile Data: Full name, athlete handle, bio, profile photo, and athletic archetype (e.g. Hybrid Athlete, Runner, Powerlifter).
                • Workout & Training Logs: Exercises, sets, repetitions, weights, heart rate metrics, workout duration, and personal records.
                • Run & GPS Tracking: Distance, pace, splits, cadence, and optional geolocation tracks when you actively start and record outdoor runs.
                • Nutrition & Food Logs: Meals logged, macronutrient breakdowns (protein, carbs, fats), calorie counts, hydration levels, and intermittent fasting windows.
                • Camera & Visual Data: Camera captures used strictly for on-device or cloud-assisted food scanning and macro estimation. Photos are processed solely for logging and are never used for facial recognition or commercial advertising.
                • HealthKit & Apple Watch: With your explicit permission, Solxce integrates with Apple HealthKit to read and write active energy burned, resting heart rate, sleep duration, and workout sessions. HealthKit data is never used for marketing.
                • Technical Information: Crash reports, app diagnostic logs, device OS version, and anonymous performance telemetry.
                """
            )

            policySection(
                title: "3. How We Use Your Data",
                content: """
                We use your data strictly to provide, personalize, and improve your athletic experience:
                • Generating customized AI workout suggestions, recovery scores, and pacing strategies.
                • Syncing your progress across devices (iPhone, Apple Watch, and web).
                • Powering the Solxce community feed and leaderboards (only if you choose to publish a post publicly).
                • Managing subscription tiers, billing verification, and customer support inquiries.
                """
            )

            policySection(
                title: "4. HealthKit & Sensitive Data Protection",
                content: """
                In compliance with Apple App Store Review Guidelines:
                • Solxce will not use or disclose HealthKit data to third parties for advertising, marketing, or use-based data mining.
                • You can revoke Apple Health access at any time through iOS Settings > Health > Data Access & Devices > Solxce.
                • Health data stored in Solxce is encrypted at rest (AES-256) and in transit (TLS 1.3).
                """
            )

            policySection(
                title: "5. Data Retention & Account Deletion",
                content: """
                You have full control over your data:
                • You can edit or delete individual workout logs, food items, run tracks, or posts anytime within the app.
                • You can request complete account deletion directly in Settings > Reset Account & Local Storage, or by emailing support@solxce.app. Upon request, all personal identifiers and cloud backups are purged within 30 days.
                """
            )

            policySection(
                title: "6. Children's Privacy",
                content: """
                Solxce is not intended for individuals under the age of 13 (or under 16 in certain jurisdictions). We do not knowingly collect personal data from minors.
                """
            )
        }
    }

    // MARK: - Terms of Service Sections
    private var termsOfServiceSections: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            policySection(
                title: "1. Acceptance of Terms",
                content: """
                By downloading, accessing, or using Solxce, you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the application.
                """
            )

            policySection(
                title: "2. Medical & Fitness Disclaimer",
                content: """
                Solxce provides fitness tracking, intermittent fasting management, AI training advice, and nutritional estimates for educational and motivational purposes only. 
                
                Solxce is not a licensed medical provider and does not provide medical diagnosis, treatment, or clinical advice. Consult a physician or qualified healthcare provider before initiating any new diet, fasting protocol, or vigorous exercise regimen. You participate in physical activity at your own risk.
                """
            )

            policySection(
                title: "3. Subscriptions & In-App Purchases",
                content: """
                • Solxce Pro is offered via recurring subscriptions (Monthly or Annual) and includes access to advanced AI coaching, camera macro scanning, fasting tracker alerts, and Apple Watch synchronization.
                • Payment is charged to your Apple ID account at confirmation of purchase.
                • Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current billing period.
                • You can manage or cancel your subscription at any time in your Apple ID Account Settings.
                • Any unused portion of a free trial period will be forfeited upon subscription purchase.
                """
            )

            policySection(
                title: "4. User Content & Community Guidelines",
                content: """
                When sharing posts, comments, or workout summaries to the Solxce social feed:
                • You retain ownership of your user content, but grant Solxce a non-exclusive license to host and display it within the app ecosystem.
                • You agree not to upload content that is abusive, unlawful, harassing, defamatory, or infringes on third-party intellectual property.
                • Solxce reserves the right to moderate, hide, or remove any content violating community standards.
                """
            )

            policySection(
                title: "5. Limitation of Liability",
                content: """
                To the fullest extent permitted by applicable law, Solxce and its creators shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service.
                """
            )
        }
    }

    // MARK: - Reusable Section Builder
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.headlineFont.weight(.bold))
                .foregroundStyle(AppTheme.text)

            Text(content)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Contact Footer
    private var contactFooter: some View {
        VStack(spacing: 8) {
            Text("Questions or Privacy Requests?")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.text)

            Text("Contact our Data Protection and Compliance Team directly:")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Link(destination: URL(string: "mailto:\(LegalDocumentView.supportEmail)")!) {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                    Text(LegalDocumentView.supportEmail)
                }
                .font(AppTheme.captionFont.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(Capsule())
            }

            Text("Solxce Fitness Inc. • All Rights Reserved")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textMuted)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
    }
}

#Preview {
    LegalDocumentView()
}
