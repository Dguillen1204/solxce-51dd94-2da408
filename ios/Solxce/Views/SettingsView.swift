// Views/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @ObservedObject private var subManager = SubscriptionManager.shared
    @AppStorage("solxce_app_appearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage(AppTheme.activeAccentKey) private var selectedAccentRaw: String = AppAccentColor.volt.rawValue

    // Account Credentials State
    @State private var fullName: String = ""
    @State private var handle: String = ""
    @State private var email: String = "athlete@solxce.app"
    @State private var bio: String = ""
    @State private var isShowingPasswordChangeSheet = false

    // Payment & Card State
    @AppStorage("solxce_card_holder") private var cardHolderName: String = "Alex Rivera"
    @AppStorage("solxce_card_last4") private var cardLast4: String = "4242"
    @AppStorage("solxce_card_exp_month") private var cardExpMonth: String = "12"
    @AppStorage("solxce_card_exp_year") private var cardExpYear: String = "28"
    @AppStorage("solxce_card_brand") private var cardBrand: String = "Visa"
    @AppStorage("solxce_card_zip") private var cardBillingZip: String = "90210"

    @State private var isShowingEditCardSheet = false
    @State private var isShowingPaywall = false
    @State private var isShowingDeleteAccountAlert = false
    @State private var isShowingLegalSheet = false
    @State private var selectedLegalDoc: LegalDocumentView.DocumentType = .privacy
    @State private var saveSuccessToast = false
    @State private var passwordSuccessToast = false

    var currentProfile: UserProfile {
        if let existing = userProfiles.first {
            return existing
        }
        return UserProfile(
            fullName: "Alex Rivera",
            handle: "alex_solxce",
            athleteType: .hybrid,
            bio: "Hybrid athlete chasing heavy lifts and fast miles."
        )
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // MARK: - Header Profile Preview
                    profileHeaderSummary

                    // MARK: - Appearance (Dark / Light / System)
                    appearanceSection

                    // MARK: - Vibrant Theme Color Selection
                    vibrantColorPaletteSection

                    // MARK: - Account Details (Username, Name, Email, Bio)
                    accountDetailsSection

                    // MARK: - Security & Password
                    securitySection

                    // MARK: - Payment & Credit Card Details
                    billingAndCardSection

                    // MARK: - Preferences & Notifications
                    preferencesSection

                    // MARK: - App Info & Destructive Actions
                    aboutAndDangerSection
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Settings")
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
            .onAppear {
                loadProfileData()
            }
            .sheet(isPresented: $isShowingPasswordChangeSheet) {
                ChangePasswordSheet(
                    onSuccess: {
                        passwordSuccessToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            passwordSuccessToast = false
                        }
                    }
                )
            }
            .sheet(isPresented: $isShowingEditCardSheet) {
                EditPaymentCardSheet(
                    cardHolder: $cardHolderName,
                    cardLast4: $cardLast4,
                    expMonth: $cardExpMonth,
                    expYear: $cardExpYear,
                    brand: $cardBrand,
                    zip: $cardBillingZip
                )
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $isShowingLegalSheet) {
                LegalDocumentView(selectedDoc: selectedLegalDoc)
            }
            .alert("Delete Athlete Account", isPresented: $isShowingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    currentProfile.fullName = "Athlete"
                    currentProfile.handle = "athlete"
                    currentProfile.bio = ""
                    try? modelContext.save()
                    dismiss()
                }
            } message: {
                Text("This will wipe your workout sessions, run logs, and personal settings from this device. This cannot be undone.")
            }
            .overlay(alignment: .bottom) {
                if saveSuccessToast {
                    toastBanner(text: "Profile changes saved successfully", icon: "checkmark.circle.fill", color: AppTheme.primary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if passwordSuccessToast {
                    toastBanner(text: "Password updated successfully", icon: "lock.shield.fill", color: AppTheme.primary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: saveSuccessToast)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: passwordSuccessToast)
        }
        .preferredColorScheme(currentAppearance.colorScheme)
    }

    private func loadProfileData() {
        fullName = currentProfile.fullName
        handle = currentProfile.handle
        bio = currentProfile.bio
    }

    private func saveAccountDetails() {
        currentProfile.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        currentProfile.handle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        currentProfile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        saveSuccessToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            saveSuccessToast = false
        }
    }

    // MARK: - Toast Banner
    private func toastBanner(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(AppTheme.captionFont.weight(.semibold))
                .foregroundStyle(AppTheme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surfaceRaised)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.hairline, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
        .padding(.bottom, 24)
    }

    // MARK: - Profile Summary Header
    private var profileHeaderSummary: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.3), AppTheme.primary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                if let data = currentProfile.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                } else {
                    Text(String(currentProfile.fullName.prefix(2).uppercased()))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(currentProfile.fullName)
                        .font(AppTheme.headlineFont.weight(.bold))
                        .foregroundStyle(AppTheme.text)
                    if subManager.isPro {
                        Text("PRO")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.onPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }

                Text("@\(currentProfile.handle)")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(email)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                .stroke(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Appearance Section (Dark / Light / System)
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Appearance", subtitle: "Switch between Dark Mode, Light Mode, or follow System", icon: "circle.lefthalf.filled")

            HStack(spacing: 10) {
                let options: [AppAppearance] = [.system, .dark, .light]
                ForEach(options, id: \.self) { appearance in
                    let isSelected = currentAppearance == appearance
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            appAppearanceRaw = appearance.rawValue
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? AppTheme.primary : AppTheme.surfaceRaised)
                                    .frame(width: 44, height: 44)

                                Image(systemName: appearance.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(isSelected ? Color.black : AppTheme.text)
                            }

                            Text(appearance.title)
                                .font(AppTheme.captionFont.weight(isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? AppTheme.text : AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? AppTheme.surfaceRaised : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                .stroke(isSelected ? AppTheme.primary : AppTheme.hairline, lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Vibrant Theme Color Section
    private var vibrantColorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Theme Color & Accents",
                subtitle: "Customize the high-energy vibrant accent across your dashboard & telemetry",
                icon: "paintpalette.fill"
            )

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(AppAccentColor.allCases) { accent in
                    let isSelected = (selectedAccentRaw == accent.rawValue)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedAccentRaw = accent.rawValue
                            UserDefaults.standard.set(accent.rawValue, forKey: AppTheme.activeAccentKey)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Swatch Circle with gradient glow
                            ZStack {
                                Circle()
                                    .fill(accent.gradient)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: accent.color.opacity(isSelected ? 0.6 : 0.2), radius: isSelected ? 6 : 2)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundStyle(accent == .monochrome ? Color.black : Color.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(accent.displayName)
                                    .font(AppTheme.subheadlineFont.weight(isSelected ? .bold : .semibold))
                                    .foregroundStyle(isSelected ? AppTheme.text : AppTheme.textSecondary)
                                    .lineLimit(1)

                                Text(accent.hexCode)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isSelected ? AppTheme.surfaceRaised : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                .stroke(isSelected ? accent.color : AppTheme.hairline, lineWidth: isSelected ? 2.0 : 1.0)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Account Details (Username, Full Name, Email, Bio)
    private var accountDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Account & Profile", subtitle: "Update your athlete identity, handle, and bio", icon: "person.crop.circle")

            VStack(spacing: 12) {
                // Full Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("FULL NAME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("Full Name", text: $fullName)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                        .padding(10)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }

                // Username / Handle
                VStack(alignment: .leading, spacing: 4) {
                    Text("USERNAME / HANDLE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 4) {
                        Text("@")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.primary)

                        TextField("username", text: $handle)
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.text)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(10)
                    .background(AppTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }

                // Email Address
                VStack(alignment: .leading, spacing: 4) {
                    Text("EMAIL ADDRESS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("Email", text: $email)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(10)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }

                // Athlete Bio
                VStack(alignment: .leading, spacing: 4) {
                    Text("ATHLETE BIO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...3)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                        .padding(10)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }

                // Save Profile Button
                Button {
                    saveAccountDetails()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Save Profile Changes")
                            .font(AppTheme.headlineFont)
                    }
                    .foregroundStyle(AppTheme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: - Security & Password Section
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Security & Credentials", subtitle: "Manage authentication and password protection", icon: "lock.shield.fill")

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: "key.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account Password")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("Last updated 30 days ago")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        isShowingPasswordChangeSheet = true
                    } label: {
                        Text("Change")
                            .font(AppTheme.captionFont.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.field)
                            .clipShape(Capsule())
                    }
                }

                Divider().overlay(AppTheme.hairline)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: "faceid")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Face ID & Biometrics")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Text("Quick unlock for workouts & logs")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .tint(AppTheme.primary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: - Billing & Credit Card Details Section
    private var billingAndCardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Billing & Payment Method", subtitle: "Manage Apple Pay, credit cards, billing & trial schedule", icon: "creditcard.fill")

            VStack(spacing: 12) {
                // Subscription Status Row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.primary.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(subManager.isPro ? "Solxce Pro Member" : "Solxce Standard")
                                .font(AppTheme.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.text)
                            
                            if subManager.isInTrial {
                                Text("TRIAL")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(AppTheme.onPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.primary)
                                    .clipShape(Capsule())
                            }
                        }

                        if subManager.isInTrial {
                            Text("7-Day Free Trial ends \(subManager.trialBillingFormattedDate). Auto-charges \(subManager.activePlan.postTrialChargeText).")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.primary)
                        } else {
                            Text(subManager.isPro ? "\(subManager.activePlan.title) • Active" : "Upgrade for AI vision, watch sync & stats")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        isShowingPaywall = true
                    } label: {
                        Text(subManager.isPro ? "Manage" : "Upgrade")
                            .font(AppTheme.captionFont.weight(.bold))
                            .foregroundStyle(subManager.isPro ? AppTheme.text : AppTheme.onPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(subManager.isPro ? AppTheme.field : AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }

                Divider().overlay(AppTheme.hairline)

                // Active Payment Method Details (Apple Pay / Credit Card)
                VStack(spacing: 10) {
                    HStack {
                        HStack(spacing: 8) {
                            if subManager.paymentMethod == .applePay {
                                HStack(spacing: 2) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Pay")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(AppTheme.text)

                                Text("Default Payment Method")
                                    .font(AppTheme.captionFont.weight(.medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            } else {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.primary)
                                Text("\(cardBrand) ending in •••• \(cardLast4)")
                                    .font(AppTheme.bodyFont.weight(.bold))
                                    .foregroundStyle(AppTheme.text)
                            }
                        }

                        Spacer()

                        Button {
                            isShowingEditCardSheet = true
                        } label: {
                            Text(subManager.paymentMethod == .applePay ? "Switch Card" : "Edit Card")
                                .font(AppTheme.captionFont.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                        }
                    }

                    if subManager.paymentMethod == .applePay {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CONNECTED WALLET")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("Apple Pay Secure Token")
                                    .font(AppTheme.captionFont.weight(.medium))
                                    .foregroundStyle(AppTheme.text)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("NEXT BILLING")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(subManager.isInTrial ? subManager.trialBillingFormattedDate : "Monthly/Annual")
                                    .font(AppTheme.captionFont.weight(.medium))
                                    .foregroundStyle(AppTheme.text)
                            }
                        }
                        .padding(10)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CARDHOLDER")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(cardHolderName)
                                    .font(AppTheme.captionFont.weight(.medium))
                                    .foregroundStyle(AppTheme.text)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("EXPIRES")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("\(cardExpMonth)/\(cardExpYear)")
                                    .font(AppTheme.captionFont.weight(.medium))
                                    .foregroundStyle(AppTheme.text)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("BILLING ZIP")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(cardBillingZip)
                                    .font(AppTheme.captionFont.weight(.medium))
                                    .foregroundStyle(AppTheme.text)
                            }
                        }
                        .padding(10)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
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
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Preferences", subtitle: "Workout units and companion integrations", icon: "slider.horizontal.3")

            VStack(spacing: 12) {
                HStack {
                    Text("Weight Units")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("Pounds (lbs)")
                        .font(AppTheme.captionFont.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Divider().overlay(AppTheme.hairline)

                HStack {
                    Text("Distance Units")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("Miles (mi)")
                        .font(AppTheme.captionFont.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Divider().overlay(AppTheme.hairline)

                HStack {
                    Text("Audio Cues During Runs")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .tint(AppTheme.primary)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: - About and Danger Zone
    private var aboutAndDangerSection: some View {
        VStack(spacing: 12) {
            // Legal & Compliance Row
            VStack(spacing: 0) {
                Button {
                    selectedLegalDoc = .privacy
                    isShowingLegalSheet = true
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.primary)
                        Text("Privacy Policy")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(AppTheme.Spacing.md)
                }

                Divider()
                    .overlay(AppTheme.hairline)

                Button {
                    selectedLegalDoc = .terms
                    isShowingLegalSheet = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.primary)
                        Text("Terms of Service")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )

            Button(role: .destructive) {
                isShowingDeleteAccountAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset Account & Local Storage")
                }
                .font(AppTheme.captionFont.weight(.semibold))
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }

            VStack(spacing: 3) {
                Text("Solxce Hybrid Fitness • Version 1.4.2")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Crafted for high performance training")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers
    private func sectionHeader(title: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                Text(title)
                    .font(AppTheme.headlineFont.weight(.bold))
                    .foregroundStyle(AppTheme.text)
            }
            Text(subtitle)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Change Password Modal Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSuccess: () -> Void

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Update Credentials")
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.text)
                        Text("Choose a strong password with at least 8 characters.")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CURRENT PASSWORD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        SecureField("Current password", text: $currentPassword)
                            .padding(12)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("NEW PASSWORD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        SecureField("At least 8 characters", text: $newPassword)
                            .padding(12)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONFIRM NEW PASSWORD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        SecureField("Re-enter new password", text: $confirmPassword)
                            .padding(12)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    Button {
                        validateAndSave()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Update Password")
                                .font(AppTheme.headlineFont.weight(.bold))
                                .foregroundStyle(AppTheme.onPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                    .padding(.top, 10)
                }
                .padding(AppTheme.Spacing.screenMargin)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func validateAndSave() {
        errorMessage = nil
        if currentPassword.isEmpty {
            errorMessage = "Please enter your current password."
            return
        }
        if newPassword.count < 8 {
            errorMessage = "New password must be at least 8 characters."
            return
        }
        if newPassword != confirmPassword {
            errorMessage = "New passwords do not match."
            return
        }

        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSaving = false
            dismiss()
            onSuccess()
        }
    }
}

// MARK: - Edit Payment Card Sheet
struct EditPaymentCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cardHolder: String
    @Binding var cardLast4: String
    @Binding var expMonth: String
    @Binding var expYear: String
    @Binding var brand: String
    @Binding var zip: String

    @State private var cardNumberInput: String = ""
    @State private var cardHolderInput: String = ""
    @State private var expInput: String = ""
    @State private var cvvInput: String = ""
    @State private var zipInput: String = ""
    @State private var brandSelection: String = "Visa"
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    let cardBrands = ["Visa", "Mastercard", "Amex", "Apple Pay"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Credit Card Visual Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.22, green: 0.22, blue: 0.26)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("SOLXCE ATHLETE PAY")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.primary)
                                Spacer()
                                Image(systemName: "wave.3.forward.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.primary)
                            }

                            Spacer()

                            Text(cardNumberInput.isEmpty ? "•••• •••• •••• \(cardLast4)" : formatCardNumber(cardNumberInput))
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)

                            Spacer()

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CARDHOLDER")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text(cardHolderInput.isEmpty ? cardHolder.uppercased() : cardHolderInput.uppercased())
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("EXPIRES")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text(expInput.isEmpty ? "\(expMonth)/\(expYear)" : expInput)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(18)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Card Brand Selection
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CARD NETWORK")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        Picker("Card Network", selection: $brandSelection) {
                            ForEach(cardBrands, id: \.self) { brand in
                                Text(brand).tag(brand)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Card Number
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CARD NUMBER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        TextField("4242 4242 4242 4242", text: $cardNumberInput)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    // Cardholder Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAME ON CARD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        TextField("Full Name", text: $cardHolderInput)
                            .padding(12)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    // Expiration & CVV
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EXPIRATION (MM/YY)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary)

                            TextField("MM/YY", text: $expInput)
                                .keyboardType(.numbersAndPunctuation)
                                .padding(12)
                                .background(AppTheme.field)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("SECURITY CODE (CVV)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary)

                            SecureField("123", text: $cvvInput)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(AppTheme.field)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                        }
                    }

                    // Billing Zip
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BILLING POSTAL / ZIP CODE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)

                        TextField("ZIP Code", text: $zipInput)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(12)
                            .background(AppTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                    }

                    // Save Button
                    Button {
                        saveCardDetails()
                    } label: {
                        if isSaving {
                            ProgressView().tint(.black)
                        } else {
                            Text("Save Payment Details")
                                .font(AppTheme.headlineFont.weight(.bold))
                                .foregroundStyle(AppTheme.onPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                    .padding(.top, 10)
                }
                .padding(AppTheme.Spacing.screenMargin)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Payment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear {
                cardHolderInput = cardHolder
                zipInput = zip
                brandSelection = brand
                expInput = "\(expMonth)/\(expYear)"
            }
        }
    }

    private func formatCardNumber(_ input: String) -> String {
        let cleaned = input.replacingOccurrences(of: " ", with: "")
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }

    private func saveCardDetails() {
        errorMessage = nil
        let cleanedNum = cardNumberInput.replacingOccurrences(of: " ", with: "")
        if !cleanedNum.isEmpty && cleanedNum.count >= 4 {
            cardLast4 = String(cleanedNum.suffix(4))
        }
        if !cardHolderInput.trimmingCharacters(in: .whitespaces).isEmpty {
            cardHolder = cardHolderInput.trimmingCharacters(in: .whitespaces)
        }
        if !zipInput.trimmingCharacters(in: .whitespaces).isEmpty {
            zip = zipInput.trimmingCharacters(in: .whitespaces)
        }
        brand = brandSelection

        if expInput.contains("/") {
            let parts = expInput.components(separatedBy: "/")
            if parts.count >= 2 {
                expMonth = parts[0].trimmingCharacters(in: .whitespaces)
                expYear = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }

        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSaving = false
            dismiss()
        }
    }
}
