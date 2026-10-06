// Views/CreateMediaPostSheet.swift
import SwiftUI

struct CreateMediaPostSheet: View {
    @Environment(\.dismiss) private var dismiss

    var authorName: String
    var authorHandle: String
    var athleteType: AthleteType
    var authorProfileImageData: Data? = nil
    var isPublicAuthor: Bool = true
    var onPost: (AthletePost) -> Void

    // Form State
    @State private var selectedMediaType: PostMediaType = .photo
    @State private var selectedMediaPreset: MediaPreset = MediaPreset.defaults[0]
    @State private var selectedAudio: AudioTrack? = AudioTrack.library[0]
    @State private var workoutFocus: String = "Chest & Heavy Hypertrophy"
    @State private var workoutStats: String = "5 sets · 315 lbs Bench Press PR"
    @State private var caption: String = "Crushed today's session! Progressive overload is hitting all the right marks. ⚡"
    
    // TikTok-style Rich Text Overlay State
    @State private var textOverlay: String = "NEW BENCH PR 🔥"
    @State private var fontStyle: TikTokFontStyle = .neon
    @State private var highlightMode: TikTokHighlightMode = .filled
    @State private var textColorHex: String = "#CCFF00"
    @State private var fontSize: CGFloat = 16
    @State private var textAlignment: TextAlignment = .center
    @State private var showingTextEditorSheet: Bool = false

    // Multi-Photo Carousel State
    @State private var activeCarouselPhotos: [PostMediaItem] = [
        PostMediaItem(id: "photo_1", title: "Heavy Barbell Lockout", iconName: "dumbbell.fill", gradientHexes: ["#1F1111", "#3D1A1A"], subtitle: "Photo 1 · 315 lbs Lockout", isVideo: false),
        PostMediaItem(id: "photo_2", title: "Form & Velocity Bar Path", iconName: "chart.line.uptrend.xyaxis", gradientHexes: ["#111926", "#1E2C44"], subtitle: "Photo 2 · 0.44 m/s", isVideo: false),
        PostMediaItem(id: "photo_3", title: "Post-Set Hypertrophy", iconName: "figure.arms.open", gradientHexes: ["#1A1608", "#382F10"], subtitle: "Photo 3 · Peak Pump", isVideo: false)
    ]
    @State private var previewPageIndex: Int = 0

    // Single Video State
    @State private var singleVideoItem: PostMediaItem = PostMediaItem(
        id: "video_1",
        title: "Workout Reel",
        iconName: "figure.strengthtraining.traditional",
        gradientHexes: ["#1F0E0E", "#3D1A1A"],
        subtitle: "4K 60fps Form Clip",
        isVideo: true
    )

    // Sheet Presentations
    @State private var showingAudioPicker: Bool = false
    @State private var showingAddPhotoDialog: Bool = false
    @State private var showingScreenLibraryPicker: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Mode Selector: Multi-Photo Carousel vs Video
                    mediaTypePicker

                    // 1. Interactive 9:16 Aspect Media Preview Viewport with Music on Top & Swipe
                    mediaPreviewViewport

                    // Multi-Photo Item Manager (When in Photo Carousel Mode)
                    if selectedMediaType == .photo {
                        photoCarouselManager
                    }

                    // 2. Music Soundtrack Selection (Apple Music & Spotify)
                    audioTrackSelectorBar

                    // 3. Caption & Details Input
                    captionInputArea
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.top, 12)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        commitAndPublishPost()
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showingAudioPicker) {
                AudioPickerSheet(selectedAudio: $selectedAudio)
            }
            .sheet(isPresented: $showingScreenLibraryPicker) {
                ScreenLibraryPickerSheet { item in
                    insertScreenLibraryItem(item)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Media Type Picker (Multi-Photo Carousel vs Single Video)
    private var mediaTypePicker: some View {
        HStack(spacing: 8) {
            ForEach(PostMediaType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMediaType = type
                        previewPageIndex = 0
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 13, weight: .bold))
                        Text(type == .photo ? "Multi-Photo Carousel (\(activeCarouselPhotos.count))" : "Video Reel")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedMediaType == type ? AppTheme.primary : AppTheme.surface)
                    .foregroundColor(selectedMediaType == type ? .black : AppTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 1. 9:16 Aspect Media Preview Viewport
    private var mediaPreviewViewport: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("POST PREVIEW (9:16)")
                    .font(AppTheme.eyebrowFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(1.5)

                Spacer()

                if selectedMediaType == .photo && activeCarouselPhotos.count > 1 {
                    Text("Swipe left/right to test carousel")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            ZStack(alignment: .bottom) {
                // Carousel or Video Canvas
                if selectedMediaType == .photo {
                    TabView(selection: $previewPageIndex) {
                        ForEach(Array(activeCarouselPhotos.enumerated()), id: \.element.id) { index, photo in
                            singleSlideCanvas(item: photo)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 380)
                    .clipped()
                } else {
                    singleSlideCanvas(item: singleVideoItem)
                        .frame(height: 380)
                        .clipped()
                }

                // Top: Music on Top Badge + Author Pill + Page Badge
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        // User Avatar
                        Circle()
                            .fill(AppTheme.surfaceRaised)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: athleteType.iconName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(athleteType.badgeColor)
                            )

                        Text("@\(authorHandle)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        // Page badge for photo carousel
                        if selectedMediaType == .photo && activeCarouselPhotos.count > 1 {
                            HStack(spacing: 3) {
                                Image(systemName: "square.stack.3d.forward.dottedline.fill")
                                    .font(.system(size: 9))
                                Text("\(previewPageIndex + 1)/\(activeCarouselPhotos.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        } else if selectedMediaType == .video {
                            HStack(spacing: 3) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 9))
                                Text("REEL")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.65))
                            .foregroundColor(AppTheme.primary)
                            .clipShape(Capsule())
                        }

                        // Music Track Tag on Top
                        if let audio = selectedAudio {
                            HStack(spacing: 4) {
                                Image(systemName: audio.platform.iconName)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(audio.platform.brandColor)

                                EqualizerAnimationView()
                                    .frame(width: 10, height: 8)
                                    .foregroundColor(AppTheme.primary)

                                Text(audio.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: 90, alignment: .leading)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        }
                    }
                    .padding(10)

                    Spacer()
                }

                // Bottom Gradient Scrim with Dots & Caption Preview
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)

                VStack(alignment: .leading, spacing: 4) {
                    // Carousel page dots
                    if selectedMediaType == .photo && activeCarouselPhotos.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(0..<activeCarouselPhotos.count, id: \.self) { dotIdx in
                                Capsule()
                                    .fill(dotIdx == previewPageIndex ? AppTheme.primary : Color.white.opacity(0.4))
                                    .frame(width: dotIdx == previewPageIndex ? 14 : 4, height: 4)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: previewPageIndex)
                            }
                        }
                        .padding(.bottom, 2)
                    }

                    Text(workoutFocus.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(AppTheme.primary)
                        .tracking(1)

                    Text(caption.isEmpty ? "Your caption will appear here..." : caption)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )
        }
    }

    // Canvas background renderer for preview
    private func singleSlideCanvas(item: PostMediaItem) -> some View {
        ZStack {
            LinearGradient(
                colors: item.gradientColors.isEmpty ? [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.35, green: 0.1, blue: 0.1)] : item.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                Circle()
                    .fill(athleteType.badgeColor.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: item.iconName)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(athleteType.badgeColor)
                    )

                if let sub = item.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }

                if !textOverlay.isEmpty {
                    TikTokTextBadgeView(
                        text: textOverlay,
                        fontStyle: fontStyle,
                        highlightMode: highlightMode,
                        textColor: Color(hex: textColorHex),
                        fontSize: fontSize,
                        alignment: textAlignment
                    )
                    .onTapGesture {
                        showingTextEditorSheet = true
                    }
                }
            }
        }
    }

    // MARK: - Multi-Photo Carousel Manager (Add, Remove, Reorder Pictures)
    private var photoCarouselManager: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CAROUSEL PICTURES (\(activeCarouselPhotos.count))")
                    .font(AppTheme.eyebrowFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .tracking(1.5)

                Spacer()

                Button {
                    addNewPhotoToCarousel()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add Picture")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(activeCarouselPhotos.enumerated()), id: \.element.id) { index, photo in
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: photo.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 110)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Image(systemName: photo.iconName)
                                                .font(.system(size: 20))
                                                .foregroundColor(AppTheme.primary)
                                            Text("Photo \(index + 1)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(previewPageIndex == index ? AppTheme.primary : AppTheme.hairline, lineWidth: previewPageIndex == index ? 2 : 1)
                                    )
                                    .onTapGesture {
                                        withAnimation { previewPageIndex = index }
                                    }

                                if activeCarouselPhotos.count > 1 {
                                    Button {
                                        withAnimation {
                                            activeCarouselPhotos.remove(at: index)
                                            if previewPageIndex >= activeCarouselPhotos.count {
                                                previewPageIndex = max(0, activeCarouselPhotos.count - 1)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black))
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }

                            Text(photo.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 80)
                                .lineLimit(1)
                        }
                    }

                    // Quick Add Photo Tile
                    Button {
                        showingScreenLibraryPicker = true
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .frame(width: 80, height: 110)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo.stack.fill")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(AppTheme.primary)
                                        Text("Screen Library")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(AppTheme.primary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.horizontal, 4)
                                )
                            Text("Add Screen")
                                .font(.system(size: 9))
                                .foregroundColor(.clear)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func insertScreenLibraryItem(_ item: ScreenLibraryItem) {
        let mediaItem = item.toPostMediaItem()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if selectedMediaType == .photo {
                activeCarouselPhotos.append(mediaItem)
                previewPageIndex = activeCarouselPhotos.count - 1
            } else {
                singleVideoItem = mediaItem
            }
        }
    }

    private func addNewPhotoToCarousel() {
        let sampleOptions: [PostMediaItem] = [
            PostMediaItem(id: UUID().uuidString, title: "Lockout Rep", iconName: "dumbbell.fill", gradientHexes: ["#240D0D", "#4A1818"], subtitle: "Photo \(activeCarouselPhotos.count + 1) · Max Effort", isVideo: false),
            PostMediaItem(id: UUID().uuidString, title: "Pace & Route", iconName: "map.fill", gradientHexes: ["#0E261D", "#1C4A39"], subtitle: "Photo \(activeCarouselPhotos.count + 1) · GPS Split", isVideo: false),
            PostMediaItem(id: UUID().uuidString, title: "Bar Path Metric", iconName: "chart.line.uptrend.xyaxis", gradientHexes: ["#141926", "#212B42"], subtitle: "Photo \(activeCarouselPhotos.count + 1) · Form Tracking", isVideo: false),
            PostMediaItem(id: UUID().uuidString, title: "Physique Check", iconName: "figure.arms.open", gradientHexes: ["#241505", "#472808"], subtitle: "Photo \(activeCarouselPhotos.count + 1) · Pump Status", isVideo: false)
        ]
        let newPhoto = sampleOptions[activeCarouselPhotos.count % sampleOptions.count]
        withAnimation(.spring()) {
            activeCarouselPhotos.append(newPhoto)
            previewPageIndex = activeCarouselPhotos.count - 1
        }
    }

    // MARK: - 2. Music Soundtrack Bar (Apple Music & Spotify)
    private var audioTrackSelectorBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MUSIC SOUNDTRACK (ON TOP)")
                .font(AppTheme.eyebrowFont)
                .foregroundColor(AppTheme.textSecondary)
                .tracking(1.5)

            Button {
                showingAudioPicker = true
            } label: {
                HStack(spacing: 12) {
                    if let audio = selectedAudio {
                        Image(systemName: audio.platform.iconName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(audio.platform.brandColor)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(audio.title)
                                    .font(AppTheme.bodyFont)
                                    .foregroundColor(AppTheme.text)
                                    .lineLimit(1)

                                Text(audio.platform.rawValue)
                                    .font(.system(size: 9, weight: .black))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(audio.platform.brandColor.opacity(0.2))
                                    .foregroundColor(audio.platform.brandColor)
                                    .clipShape(Capsule())
                            }

                            Text("\(audio.artist) · \(audio.bpm) BPM · \(audio.workoutTag)")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.textMuted)

                        Text("Select Music (Apple Music / Spotify)")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.textSecondary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
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
            .buttonStyle(.plain)
        }
    }

    // MARK: - 3. Caption & Details Input
    private var captionInputArea: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("POST CAPTION & DETAILS")
                .font(AppTheme.eyebrowFont)
                .foregroundColor(AppTheme.textSecondary)
                .tracking(1.5)

            // Workout Focus
            VStack(alignment: .leading, spacing: 4) {
                Text("Workout Focus Tag")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)

                TextField("e.g. Chest & Triceps", text: $workoutFocus)
                    .font(AppTheme.bodyFont)
                    .padding(12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Caption Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Caption")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)

                TextField("Write a caption for your post...", text: $caption, axis: .vertical)
                    .lineLimit(3...5)
                    .font(AppTheme.bodyFont)
                    .padding(12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Text Sticker Overlay (TikTok Style)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Text Sticker / Overlay")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Button {
                        showingTextEditorSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "textformat")
                            Text("TikTok Text Editor")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                }

                HStack(spacing: 10) {
                    TextField("e.g. NEW PR 🔥", text: $textOverlay)
                        .font(AppTheme.bodyFont)
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button {
                        showingTextEditorSheet = true
                    } label: {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#CCFF00"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Quick Style Pill Selector
                if !textOverlay.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TikTokFontStyle.allCases) { style in
                                Button {
                                    fontStyle = style
                                } label: {
                                    Text(style.rawValue)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(fontStyle == style ? .black : AppTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(fontStyle == style ? Color(hex: "#CCFF00") : AppTheme.surface)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Commit & Publish
    private func commitAndPublishPost() {
        let finalMediaItems: [PostMediaItem] = selectedMediaType == .photo ? activeCarouselPhotos : [singleVideoItem]
        let firstGradient = finalMediaItems.first?.gradientColors ?? selectedMediaPreset.gradientColors

        let newPost = AthletePost(
            authorName: authorName,
            authorHandle: authorHandle,
            athleteType: athleteType,
            authorProfileImageData: authorProfileImageData,
            isPublicAuthor: isPublicAuthor,
            timeAgo: "Just now",
            workoutTag: workoutFocus.isEmpty ? "WORKOUT LOG" : workoutFocus.uppercased(),
            workoutStats: workoutStats,
            caption: caption.isEmpty ? "Logged an epic session on Solxce." : caption,
            imageName: selectedMediaType == .photo ? "square.stack.3d.forward.dottedline.fill" : "video.fill",
            mediaType: selectedMediaType,
            mediaItems: finalMediaItems,
            mediaIconName: finalMediaItems.first?.iconName ?? selectedMediaPreset.systemIcon,
            gradientColors: firstGradient,
            audioTrack: selectedAudio,
            textOverlay: textOverlay.isEmpty ? nil : textOverlay,
            likesCount: 1,
            isLiked: true,
            comments: []
        )

        onPost(newPost)
        dismiss()
    }
}

// MARK: - Audio Picker Sheet for Apple Music & Spotify Tracks
struct AudioPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAudio: AudioTrack?

    @State private var selectedFilter: MusicService = .all
    @State private var searchQuery: String = ""

    var filteredTracks: [AudioTrack] {
        AudioTrack.library.filter { track in
            let matchesService = (selectedFilter == .all || track.platform == selectedFilter)
            let matchesQuery = searchQuery.isEmpty ||
                track.title.localizedCaseInsensitiveContains(searchQuery) ||
                track.artist.localizedCaseInsensitiveContains(searchQuery) ||
                track.workoutTag.localizedCaseInsensitiveContains(searchQuery)
            return matchesService && matchesQuery
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Platform Segment Filter
                HStack(spacing: 8) {
                    ForEach(MusicService.allCases) { service in
                        Button {
                            withAnimation(.spring()) {
                                selectedFilter = service
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: service.iconName)
                                    .font(.system(size: 11))
                                Text(service.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(selectedFilter == service ? service.brandColor : AppTheme.surface)
                            .foregroundColor(selectedFilter == service ? .black : AppTheme.text)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.vertical, 10)

                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textMuted)
                    TextField("Search Drake, Travis Scott, Hardstyle...", text: $searchQuery)
                        .font(AppTheme.bodyFont)
                }
                .padding(10)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, AppTheme.Spacing.screenMargin)
                .padding(.bottom, 8)

                // Tracks List
                List {
                    ForEach(filteredTracks) { track in
                        Button {
                            selectedAudio = track
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                // Platform Icon
                                ZStack {
                                    Circle()
                                        .fill(track.platform.brandColor.opacity(0.15))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: track.platform.iconName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(track.platform.brandColor)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(track.title)
                                            .font(AppTheme.headlineFont)
                                            .foregroundColor(AppTheme.text)
                                            .lineLimit(1)

                                        if track.isPopularInSolxce {
                                            Text("POPULAR")
                                                .font(.system(size: 8, weight: .black))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.primary)
                                                .foregroundColor(.black)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text("\(track.artist) · \(track.workoutTag)")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Text(track.formattedDuration)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(AppTheme.textMuted)

                                if selectedAudio?.id == track.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Select Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
