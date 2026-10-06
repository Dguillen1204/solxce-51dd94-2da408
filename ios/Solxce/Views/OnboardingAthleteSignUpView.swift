// Views/OnboardingAthleteSignUpView.swift
import SwiftUI
import SwiftData
import PhotosUI

struct OnboardingAthleteSignUpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var isCompleted: Bool

    @State private var currentStep: Int = 0
    @State private var selectedAthleteType: AthleteType = .hybrid
    @State private var fullName: String = ""
    @State private var handle: String = ""
    @State private var bio: String = ""
    @State private var selectedAvatarIcon: String = "bolt.shield.fill"
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    @State private var isPublicProfile: Bool = true

    let avatarChoices = [
        "bolt.shield.fill",
        "figure.strengthtraining.traditional",
        "figure.run",
        "flame.fill",
        "figure.cross-training",
        "figure.gymnastics",
        "figure.arms.open",
        "dumbbell.fill",
        "trophy.fill",
        "heart.fill"
    ]

    var body: some View {
        ZStack {
            AppTheme.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Progress Bar
                topProgressBar

                TabView(selection: $currentStep) {
                    // Step 0: Welcome & Basic Identity
                    identityStepView
                        .tag(0)

                    // Step 1: Athlete Archetype Selection
                    archetypeSelectionStepView
                        .tag(1)

                    // Step 2: Final Confirmation & Athlete Card Reveal
                    athleteCardRevealStepView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentStep)

                // Bottom Action Buttons
                bottomActionButtons
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        profileImageData = data
                    }
                }
            }
        }
    }

    // MARK: - Top Progress Bar
    private var topProgressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    if currentStep > 0 {
                        withAnimation { currentStep -= 1 }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(currentStep > 0 ? AppTheme.text : .clear)
                }
                .disabled(currentStep == 0)

                Spacer()

                Text("SOLXCE ATHLETE SIGN-UP")
                    .font(AppTheme.eyebrowFont)
                    .foregroundColor(AppTheme.primary)
                    .tracking(2)

                Spacer()

                Text("STEP \(currentStep + 1)/3")
                    .font(AppTheme.monoFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.top, 16)

            // Segmented Progress Track
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(index <= currentStep ? AppTheme.primary : AppTheme.surfaceRaised)
                        .frame(height: 4)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Step 0: Basic Identity
    private var identityStepView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                VStack(spacing: 8) {
                    Text("JOIN THE ROSTER")
                        .font(AppTheme.largeTitleFont)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.center)

                    Text("Set up your athletic profile to unlock workout logs, calorie targets, and the community feed.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 16)

                // Avatar & Profile Photo Choice
                VStack(spacing: 16) {
                    Text("PROFILE PICTURE & AVATAR")
                        .font(AppTheme.eyebrowFont)
                        .foregroundColor(AppTheme.textSecondary)

                    // Large Avatar with Photo Picker
                    VStack(spacing: 10) {
                        AthleteAvatarView(
                            imageData: profileImageData,
                            symbolFallback: selectedAvatarIcon,
                            initials: fullName.isEmpty ? "A" : fullName,
                            ringColor: selectedAthleteType.badgeColor,
                            size: 88,
                            showCameraBadge: true,
                            isPublic: isPublicProfile
                        )

                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                Text(profileImageData == nil ? "Upload Profile Picture" : "Change Picture")
                            }
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }

                    // Public Profile Toggle
                    Toggle(isOn: $isPublicProfile) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Image(systemName: "globe.americas.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.primary)
                                Text("Make Profile & Photo Public")
                                    .font(AppTheme.headlineFont)
                                    .foregroundColor(AppTheme.text)
                            }
                            Text("Visible in community feed and athlete leaderboards.")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .tint(AppTheme.primary)
                    .padding(.top, 4)

                    Divider()
                        .background(AppTheme.hairline)

                    // Preset Athlete Symbols
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OR CHOOSE ATHLETE ICON")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(avatarChoices, id: \.self) { icon in
                                    Button {
                                        selectedAvatarIcon = icon
                                        profileImageData = nil
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(selectedAvatarIcon == icon && profileImageData == nil ? AppTheme.primary.opacity(0.2) : AppTheme.surfaceRaised)
                                                .frame(width: 48, height: 48)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedAvatarIcon == icon && profileImageData == nil ? AppTheme.primary : AppTheme.hairline, lineWidth: selectedAvatarIcon == icon && profileImageData == nil ? 2 : 1)
                                                )

                                            Image(systemName: icon)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(selectedAvatarIcon == icon && profileImageData == nil ? AppTheme.primary : AppTheme.textSecondary)
                                        }
                                    }
                                    .buttonStyle(ScaleBounceButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
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

                // Input Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FULL NAME")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("e.g. Jordan Reed", text: $fullName)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.button)
                                    .stroke(AppTheme.hairline, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("HANDLE / USERNAME")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textSecondary)

                        HStack {
                            Text("@")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.primary)
                                .fontWeight(.bold)

                            TextField("username", text: $handle)
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.text)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.button)
                                .stroke(AppTheme.hairline, lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("ATHLETIC MOTTO / BIO")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("e.g. Daily consistency over perfection", text: $bio)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.button)
                                    .stroke(AppTheme.hairline, lineWidth: 1)
                            )
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
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 1: Athlete Archetype Picker
    private var archetypeSelectionStepView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                VStack(spacing: 8) {
                    Text("WHAT KIND OF ATHLETE ARE YOU?")
                        .font(AppTheme.largeTitleFont)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.center)

                    Text("This customizes your profile badge, community feed tag, and workout recommendations.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 16)

                // Archetype Options Grid/List
                VStack(spacing: 10) {
                    ForEach(AthleteType.allCases) { type in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedAthleteType = type
                            }
                        } label: {
                            HStack(spacing: 14) {
                                // Icon Circle
                                ZStack {
                                    Circle()
                                        .fill(type.badgeColor.opacity(0.2))
                                        .frame(width: 48, height: 48)

                                    Image(systemName: type.iconName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(type.badgeColor)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(type.rawValue)
                                            .font(AppTheme.headlineFont)
                                            .foregroundColor(AppTheme.text)

                                        Text(type.shortTag)
                                            .font(AppTheme.eyebrowFont)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(type.badgeColor.opacity(0.18))
                                            .foregroundColor(type.badgeColor)
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                                    }

                                    Text(type.description)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                ZStack {
                                    Circle()
                                        .stroke(selectedAthleteType == type ? AppTheme.primary : AppTheme.hairline, lineWidth: 2)
                                        .frame(width: 22, height: 22)

                                    if selectedAthleteType == type {
                                        Circle()
                                            .fill(AppTheme.primary)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            }
                            .padding(14)
                            .background(selectedAthleteType == type ? AppTheme.surfaceRaised : AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                                    .stroke(selectedAthleteType == type ? type.badgeColor : AppTheme.hairline, lineWidth: selectedAthleteType == type ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(ScaleBounceButtonStyle())
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Step 2: Athlete Card Reveal & Confirmation
    private var athleteCardRevealStepView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                VStack(spacing: 8) {
                    Text("YOUR SOLXCE ATHLETE PASS")
                        .font(AppTheme.largeTitleFont)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.center)

                    Text("Ready to show up on your profile and across the community feed.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // Holographic Athlete Pass Card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SOLXCE OFFICIAL ROSTER")
                                .font(AppTheme.eyebrowFont)
                                .foregroundColor(AppTheme.textMuted)
                                .tracking(1.5)

                            Text("MEMBER ID #\(abs((fullName.isEmpty ? "ATHLETE" : fullName).hashValue % 90000 + 10000))")
                                .font(AppTheme.monoFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        SolxceLogoView(size: 32)
                    }

                    // Athlete Header Presentation
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(selectedAthleteType.badgeColor, lineWidth: 3)
                                .frame(width: 74, height: 74)

                            Circle()
                                .fill(AppTheme.surfaceRaised)
                                .frame(width: 66, height: 66)

                            Image(systemName: selectedAvatarIcon)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(selectedAthleteType.badgeColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fullName.isEmpty ? "Solxce Athlete" : fullName)
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.text)

                            Text("@\(handle.isEmpty ? "athlete" : handle.lowercased().replacingOccurrences(of: " ", with: "_"))")
                                .font(AppTheme.monoFont)
                                .foregroundColor(AppTheme.textSecondary)

                            // Athlete Archetype Tag Badge
                            HStack(spacing: 6) {
                                Image(systemName: selectedAthleteType.iconName)
                                    .font(.system(size: 11, weight: .bold))
                                Text(selectedAthleteType.rawValue)
                                    .font(AppTheme.eyebrowFont)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedAthleteType.badgeColor.opacity(0.18))
                            .foregroundColor(selectedAthleteType.badgeColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.tag))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.tag)
                                    .stroke(selectedAthleteType.badgeColor.opacity(0.4), lineWidth: 1)
                            )
                        }

                        Spacer()
                    }

                    Divider()
                        .background(AppTheme.hairline)

                    // Bio & Manifesto
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ATHLETIC MISSION")
                            .font(AppTheme.eyebrowFont)
                            .foregroundColor(AppTheme.textMuted)

                        Text(bio.isEmpty ? selectedAthleteType.description : bio)
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Feed Visibility Notice
                    HStack(spacing: 8) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primary)

                        Text("Your '\(selectedAthleteType.rawValue)' badge will appear on your posts in the community feed.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surfaceRaised.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                }
                .padding(20)
                .background(
                    ZStack {
                        AppTheme.surface
                        LinearGradient(
                            colors: [selectedAthleteType.badgeColor.opacity(0.12), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                        .stroke(selectedAthleteType.badgeColor.opacity(0.5), lineWidth: 1.5)
                )
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Bottom Action Buttons
    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            Button {
                if currentStep < 2 {
                    withAnimation { currentStep += 1 }
                } else {
                    completeSignUp()
                }
            } label: {
                HStack {
                    Text(currentStep == 2 ? "FINISH & ENTER SOLXCE" : "CONTINUE")
                        .font(AppTheme.headlineFont)
                        .tracking(1)

                    Image(systemName: currentStep == 2 ? "checkmark.circle.fill" : "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.primary)
                .foregroundColor(AppTheme.onPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                .shadow(color: AppTheme.primary.opacity(0.35), radius: 8, y: 4)
            }
            .buttonStyle(ScaleBounceButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.screenMargin)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(AppTheme.surface.opacity(0.85).ignoresSafeArea())
    }

    // MARK: - Save and Commit
    private func completeSignUp() {
        let finalName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Solxce Athlete" : fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "solxce_athlete" : handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: " ", with: "_")
        let finalBio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedAthleteType.description : bio.trimmingCharacters(in: .whitespacesAndNewlines)

        let descriptor = FetchDescriptor<UserProfile>()
        if let existingProfiles = try? modelContext.fetch(descriptor), let existing = existingProfiles.first {
            existing.fullName = finalName
            existing.handle = finalHandle
            existing.athleteType = selectedAthleteType
            existing.bio = finalBio
            existing.avatarSymbol = selectedAvatarIcon
            existing.profileImageData = profileImageData
            existing.isPublicProfile = isPublicProfile
        } else {
            let newProfile = UserProfile(
                fullName: finalName,
                handle: finalHandle,
                athleteType: selectedAthleteType,
                bio: finalBio,
                avatarSymbol: selectedAvatarIcon,
                profileImageData: profileImageData,
                isPublicProfile: isPublicProfile
            )
            modelContext.insert(newProfile)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: "solxce_has_completed_athlete_signup")

        // Sync profile to cloud backend via TenxData
        Task {
            await BackendSyncService.shared.syncProfileData(
                name: finalName,
                handle: finalHandle,
                athleteType: selectedAthleteType.rawValue
            )
        }

        isCompleted = true
        dismiss()
    }
}
