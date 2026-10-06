// Views/ScreenLibraryPickerSheet.swift
import SwiftUI

/// High-craft interactive Screen Library Modal allowing athletes to choose polished app screenshot presets
struct ScreenLibraryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSelectScreen: (ScreenLibraryItem) -> Void

    @State private var selectedCategory: ScreenLibraryCategory = .all
    @State private var searchText: String = ""
    @State private var previewItem: ScreenLibraryItem? = nil

    private var filteredItems: [ScreenLibraryItem] {
        ScreenLibraryItem.library.filter { item in
            let matchesCategory = (selectedCategory == .all) || (item.category == selectedCategory)
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.screenName.localizedCaseInsensitiveContains(searchText) ||
                item.subtitle.localizedCaseInsensitiveContains(searchText) ||
                item.statValue.localizedCaseInsensitiveContains(searchText) ||
                item.badgeText.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter Rail
                categoryFilterRail

                // Grid of Screen Library Cards
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        // Header info
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SCREENSHOT LIBRARY")
                                    .font(AppTheme.eyebrowFont)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .tracking(1.5)
                                Text("Select an app screenshot to include in your post carousel")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            Spacer()
                            Text("\(filteredItems.count) Presets")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenMargin)
                        .padding(.top, 8)

                        // 2-Column Responsive Card Grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 14
                        ) {
                            ForEach(filteredItems) { item in
                                ScreenLibraryCardView(item: item) {
                                    onSelectScreen(item)
                                    dismiss()
                                } onPreview: {
                                    previewItem = item
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.screenMargin)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search workouts, runs, macros, fasting...")
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Screen Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .sheet(item: $previewItem) { item in
                ScreenDetailPreviewSheet(item: item) {
                    onSelectScreen(item)
                    previewItem = nil
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Category Filter Rail
    private var categoryFilterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ScreenLibraryCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = cat
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: cat.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == cat ? AppTheme.primary : AppTheme.surface)
                        .foregroundColor(selectedCategory == cat ? .black : AppTheme.textSecondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedCategory == cat ? Color.clear : AppTheme.hairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screenMargin)
            .padding(.vertical, 10)
        }
        .background(AppTheme.surfaceRaised)
    }
}

// MARK: - Individual Screen Library Card Thumbnail
struct ScreenLibraryCardView: View {
    let item: ScreenLibraryItem
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Mock Screen Viewport (Aspect Ratio ~9:14 for realistic mobile screen preview)
            ZStack(alignment: .topLeading) {
                // Background Gradient
                LinearGradient(
                    colors: item.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Grid Accent Pattern
                VStack(spacing: 0) {
                    // Screen Status Bar Mock
                    HStack {
                        Text(item.screenName)
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "cellularbars")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "wifi")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "battery.100")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    Spacer()

                    // Center Hero Metric
                    VStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: item.iconName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                        }

                        Text(item.statValue)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(item.statLabel)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Bottom Metric Tags
                    HStack(spacing: 4) {
                        ForEach(item.metricHighlights.prefix(2), id: \.self) { highlight in
                            Text(highlight)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }

                // Top Badge
                HStack {
                    Text(item.badgeText)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(6)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )

            // Title & Category Metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            // Quick Use Button
            Button(action: onSelect) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 11))
                    Text("Use Screenshot")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(AppTheme.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            onPreview()
        }
    }
}

// MARK: - Detailed Full Screen Preview Modal
struct ScreenDetailPreviewSheet: View {
    let item: ScreenLibraryItem
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.md) {
                // High Resolution Realistic Screen Canvas
                ZStack {
                    LinearGradient(
                        colors: item.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 20) {
                        // Screen Header
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.badgeText)
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.primary)
                                    .clipShape(Capsule())

                                Text(item.screenName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        Spacer()

                        // Center Graphic Icon & Stat
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.18))
                                    .frame(width: 80, height: 80)
                                Image(systemName: item.iconName)
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(AppTheme.primary)
                            }

                            Text(item.statValue)
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text(item.statLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        // Metric Breakdown Box
                        VStack(spacing: 8) {
                            ForEach(item.metricHighlights, id: \.self) { metric in
                                HStack {
                                    Circle()
                                        .fill(AppTheme.primary)
                                        .frame(width: 6, height: 6)
                                    Text(metric)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.primary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.Spacing.screenMargin)

                // Add to Post Action
                VStack(spacing: 8) {
                    Button(action: onConfirm) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Insert into Post Carousel")
                        }
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.button))
                    }

                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
            }
            .padding(.top, 10)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}
