// Views/AthleteAvatarView.swift
import SwiftUI
import PhotosUI
import UIKit

/// Reusable Athlete Avatar component supporting custom profile pictures,
/// athlete archetype rings, fallback athletic symbols, and public privacy badges.
struct AthleteAvatarView: View {
    var imageData: Data?
    var symbolFallback: String = "figure.cross-training"
    var initials: String = "A"
    var ringColor: Color = AppTheme.primary
    var size: CGFloat = 80
    var showCameraBadge: Bool = false
    var isPublic: Bool = true
    var onCameraTap: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Avatar Circle
            ZStack {
                // Outer Archetype Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [ringColor, ringColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size > 60 ? 3 : 2
                    )
                    .frame(width: size, height: size)

                // Background / Image Fill
                Circle()
                    .fill(AppTheme.surfaceRaised)
                    .frame(width: size - (size > 60 ? 6 : 4), height: size - (size > 60 ? 6 : 4))

                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size - (size > 60 ? 6 : 4), height: size - (size > 60 ? 6 : 4))
                        .clipShape(Circle())
                } else if !symbolFallback.isEmpty {
                    Image(systemName: symbolFallback)
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(ringColor)
                } else {
                    Text(initials.prefix(1).uppercased())
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                }
            }

            // Optional Camera Edit Button Badge
            if showCameraBadge {
                Button {
                    onCameraTap?()
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: max(24, size * 0.32), height: max(24, size * 0.32))
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.ground, lineWidth: 2)
                            )
                            .shadow(color: AppTheme.primary.opacity(0.4), radius: 4, x: 0, y: 2)

                        Image(systemName: "camera.fill")
                            .font(.system(size: max(11, size * 0.15), weight: .bold))
                            .foregroundColor(AppTheme.onPrimary)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: 2)
            }
        }
    }
}

/// Dedicated Sheet for Picking, Updating, and Configuring Public Profile Picture
struct ProfilePhotoPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var selectedIcon: String = ""
    @State private var isPublic: Bool = true
    @State private var isProcessingImage: Bool = false
    @State private var showPhotoSuccessToast: Bool = false

    private let presetAthleteIcons = [
        "bolt.shield.fill",
        "figure.run",
        "dumbbell.fill",
        "figure.cross-training",
        "figure.strengthtraining.traditional",
        "flame.fill",
        "figure.highintensity.intervaltraining",
        "figure.boxing",
        "heart.fill",
        "trophy.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Avatar Large Preview
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            AthleteAvatarView(
                                imageData: selectedImageData,
                                symbolFallback: selectedIcon.isEmpty ? profile.avatarSymbol : selectedIcon,
                                ringColor: profile.athleteType.badgeColor,
                                size: 110,
                                showCameraBadge: false
                            )

                            if isProcessingImage {
                                ProgressView()
                                    .tint(AppTheme.primary)
                                    .scaleEffect(1.4)
                                    .frame(width: 110, height: 110)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 8)

                        // Public / Private Badge indicator
                        HStack(spacing: 6) {
                            Image(systemName: isPublic ? "globe.americas.fill" : "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(isPublic ? "Public Profile & Photo" : "Private (Visible only to you)")
                                .font(AppTheme.eyebrowFont)
                        }
                        .foregroundColor(isPublic ? AppTheme.primary : AppTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((isPublic ? AppTheme.primary : AppTheme.textSecondary).opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)

                    // Photo Action Buttons
                    VStack(spacing: 10) {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 15, weight: .semibold))
                                Text(selectedImageData == nil ? "Choose Photo from Library" : "Change Profile Photo")
                                    .font(AppTheme.headlineFont)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primary)
                            .foregroundColor(AppTheme.onPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                        }

                        if selectedImageData != nil {
                            Button(role: .destructive) {
                                withAnimation {
                                    selectedImageData = nil
                                    selectedPhotoItem = nil
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Remove Custom Photo")
                                        .font(AppTheme.bodyFont)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)

                    // Public Profile & Avatar Privacy Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PRIVACY & VISIBILITY")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(spacing: 12) {
                            Toggle(isOn: $isPublic) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "globe")
                                            .foregroundColor(AppTheme.primary)
                                        Text("Make Profile & Photo Public")
                                            .font(AppTheme.headlineFont)
                                            .foregroundColor(AppTheme.text)
                                    }
                                    Text("Allow other Solxce athletes in the Feed, leaderboards, and comments to see your profile picture, stats, and workouts.")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .tint(AppTheme.primary)

                            Divider()
                                .background(AppTheme.hairline)

                            HStack(spacing: 10) {
                                Image(systemName: isPublic ? "eye.fill" : "eye.slash.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(isPublic ? AppTheme.primary : AppTheme.textSecondary)

                                Text(
                                    isPublic
                                        ? "Your profile picture and training milestones are visible to the public community."
                                        : "Your profile is private. Only you can view your photo, stats, and workouts."
                                )
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            }
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
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)

                    // Or Choose Athlete Preset Icon
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OR SELECT ATHLETE SYMBOL")
                            .font(AppTheme.eyebrowFont)
                            .tracking(1.5)
                            .foregroundColor(AppTheme.textSecondary)

                        Text("If no custom photo is chosen, this icon represents your profile.")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(presetAthleteIcons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                        if selectedImageData != nil {
                                            selectedImageData = nil
                                        }
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon && selectedImageData == nil ? profile.athleteType.badgeColor.opacity(0.2) : AppTheme.surfaceRaised)
                                                .frame(width: 52, height: 52)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            selectedIcon == icon && selectedImageData == nil ? profile.athleteType.badgeColor : AppTheme.hairline,
                                                            lineWidth: selectedIcon == icon && selectedImageData == nil ? 2 : 1
                                                        )
                                                )

                                            Image(systemName: icon)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(selectedIcon == icon && selectedImageData == nil ? profile.athleteType.badgeColor : AppTheme.textSecondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.card)
                            .stroke(AppTheme.hairline, lineWidth: 1)
                    )
                    .padding(.horizontal, AppTheme.Spacing.screenMargin)
                }
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Profile Picture & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfileChanges()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.primary)
                }
            }
            .onAppear {
                selectedImageData = profile.profileImageData
                selectedIcon = profile.avatarSymbol
                isPublic = profile.isPublicProfile
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                isProcessingImage = true
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        // Compress and resize image data if needed to keep storage lean
                        let processedData = compressProfileImage(data: data)
                        await MainActor.run {
                            selectedImageData = processedData ?? data
                            isProcessingImage = false
                        }
                    } else {
                        await MainActor.run {
                            isProcessingImage = false
                        }
                    }
                }
            }
        }
    }

    private func saveProfileChanges() {
        profile.profileImageData = selectedImageData
        if !selectedIcon.isEmpty {
            profile.avatarSymbol = selectedIcon
        }
        profile.isPublicProfile = isPublic
        try? modelContext.save()

        // Sync to cloud backend
        Task {
            await BackendSyncService.shared.syncProfileData(
                name: profile.fullName,
                handle: profile.handle,
                athleteType: profile.athleteType.rawValue
            )
        }

        dismiss()
    }

    private func compressProfileImage(data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        let maxDimension: CGFloat = 512
        let scale = min(1.0, maxDimension / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}
