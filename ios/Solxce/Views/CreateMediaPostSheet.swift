// Views/CreateMediaPostSheet.swift
import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - On-Image Text Overlay Style Model
public struct ImageTextOverlay: Codable, Hashable {
    public var text: String
    public var colorHex: String
    public var fontStyle: String // Modern, Heavy, Neon, Typewriter, Minimal
    public var alignment: String // Center, Left, Right
    public var scale: Double
    public var hasBackground: Bool
    public var verticalPosition: Double // -1.0 (top) to 1.0 (bottom), 0.0 center

    public init(
        text: String = "",
        colorHex: String = "#FFFFFF",
        fontStyle: String = "Heavy",
        alignment: String = "Center",
        scale: Double = 1.0,
        hasBackground: Bool = true,
        verticalPosition: Double = 0.0
    ) {
        self.text = text
        self.colorHex = colorHex
        self.fontStyle = fontStyle
        self.alignment = alignment
        self.scale = scale
        self.hasBackground = hasBackground
        self.verticalPosition = verticalPosition
    }
}

struct CreateMediaPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    var authorName: String = "You"
    var authorHandle: String = "athlete_you"
    var athleteType: AthleteType = .bodybuilder
    var authorProfileImageData: Data? = nil
    var isPublicAuthor: Bool = true
    var onPost: ((AthletePost) -> Void)? = nil
    var onPublish: ((AthletePost) -> Void)? = nil

    // Form inputs: Just caption, media, music & on-image text
    @State private var caption: String = ""
    @State private var activeFilter: PostVideoFilter = .normal
    @State private var selectedAudioTrack: AudioTrack? = AudioTrack.library.first
    @State private var showMusicPicker: Bool = false
    @State private var isPosting: Bool = false

    // Multi-photo and video pickers from iPhone Library
    @State private var selectedPhotosPickerItems: [PhotosPickerItem] = []
    @State private var customPickedMediaItems: [PostMediaItem] = []
    @State private var isLoadingMedia: Bool = false

    // On-Image Text Overlay State
    @State private var showTextEditorModal: Bool = false
    @State private var imageOverlayText: String = ""
    @State private var overlayColorHex: String = "#FFFFFF"
    @State private var overlayFontStyle: String = "Heavy"
    @State private var overlayHasBackground: Bool = true
    @State private var overlayPosition: Double = 0.0 // -0.8 (top), 0.0 (center), 0.8 (bottom)

    let availableColors: [String] = [
        "#FFFFFF", "#CCFF00", "#FF453A", "#FF9F0A", "#30D158", "#0A84FF", "#BF5AF2", "#000000"
    ]

    let fontStyles: [String] = ["Heavy", "Modern", "Neon", "Typewriter", "Minimal"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Main Media Hero Canvas with On-Image Text Overlay
                        mediaHeroViewport

                        // Section 2: iPhone Photos & Video Picker Controls
                        deviceMediaPickerToolbar

                        // Section 3: On-Image Text Customizer Tool
                        imageTextEditorSection

                        // Section 4: Music & Soundtrack Bar (Hear Before Applying)
                        musicAttachmentBar

                        // Section 5: Caption Input
                        captionInputField

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        AudioPreviewEngine.shared.stop()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.silver)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        publishPost()
                    } label: {
                        if isPosting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Post")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 6)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(isPosting)
                }
            }
            .sheet(isPresented: $showMusicPicker) {
                MusicPickerModal(
                    selectedTrack: $selectedAudioTrack,
                    onSelectTrack: { track in
                        selectedAudioTrack = track
                        showMusicPicker = false
                    }
                )
            }
            .sheet(isPresented: $showTextEditorModal) {
                onImageTextCustomizerSheet
            }
            .onChange(of: selectedPhotosPickerItems) { newItems in
                loadPickedMediaItems(from: newItems)
            }
            .onDisappear {
                AudioPreviewEngine.shared.stop()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Visual Viewport / Carousel Canvas with Live Text Overlay
    private var mediaHeroViewport: some View {
        let activeItems = customPickedMediaItems

        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.surfaceRaised)
                    .frame(height: 290)

                if activeItems.isEmpty {
                    PhotosPicker(
                        selection: $selectedPhotosPickerItems,
                        maxSelectionCount: 6,
                        matching: .any(of: [.images, .videos, .livePhotos, .slomoVideos]),
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.15))
                                    .frame(width: 70, height: 70)
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AppTheme.primary)
                            }
                            Text("Tap to Choose Photos or Videos")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("Access your iPhone camera roll & clips")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.silver)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if activeItems.count == 1, let singleItem = activeItems.first {
                    singleItemCanvas(singleItem)
                } else {
                    // Multi-photo Tab Carousel
                    TabView {
                        ForEach(Array(activeItems.enumerated()), id: \.element.id) { index, item in
                            singleItemCanvas(item)
                                .overlay(alignment: .topTrailing) {
                                    Text("\(index + 1)/\(activeItems.count)")
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.65))
                                        .clipShape(Capsule())
                                        .padding(12)
                                }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 290)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                // Filter Overlay Tint
                if activeFilter != .normal {
                    activeFilter.tintColor
                        .allowsHitTesting(false)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                // Render On-Image Text Overlay if added
                if !imageOverlayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack {
                        if overlayPosition > 0.3 {
                            Spacer()
                        }

                        Button {
                            showTextEditorModal = true
                        } label: {
                            Text(imageOverlayText)
                                .font(fontForStyle(overlayFontStyle))
                                .foregroundColor(Color(hex: overlayColorHex))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    overlayHasBackground
                                        ? Color.black.opacity(0.75)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)

                        if overlayPosition < -0.3 {
                            Spacer()
                        }
                    }
                    .frame(height: 290)
                }

                // Soundtrack Attached Badge
                if let audio = selectedAudioTrack {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: audio.platform.iconName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(audio.platform.brandColor)

                                Text("\(audio.title) · \(audio.artist)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Button {
                                    AudioPreviewEngine.shared.togglePlayPause(for: audio)
                                } label: {
                                    Image(systemName: AudioPreviewEngine.shared.currentlyPlayingTrack?.id == audio.id && AudioPreviewEngine.shared.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )

                            Spacer()
                        }
                        .padding(12)
                    }
                }
            }
            .frame(height: 290)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.hairline, lineWidth: 1)
            )

            // Filter Selector Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PostVideoFilter.allCases) { filter in
                        Button {
                            withAnimation { activeFilter = filter }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(activeFilter == filter ? AppTheme.primary : AppTheme.silver)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(activeFilter == filter ? AppTheme.surfaceRaised : Color.clear)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(activeFilter == filter ? AppTheme.primary : AppTheme.hairline, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func singleItemCanvas(_ item: PostMediaItem) -> some View {
        ZStack {
            if let imgData = item.customImageData, let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 290)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#1A1A24"), Color(hex: "#2D1B36")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 10) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.primary)

                    Text(item.title)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)

                    if item.isVideo {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 10))
                            Text("HD VIDEO")
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - iPhone Device Photos & Video Picker Toolbar
    private var deviceMediaPickerToolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("iPhone Photos & Videos")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                if isLoadingMedia {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !customPickedMediaItems.isEmpty {
                    Text("\(customPickedMediaItems.count) Selected")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
            }

            HStack(spacing: 12) {
                // PhotosPicker for Photos & Videos (multiple selection)
                PhotosPicker(
                    selection: $selectedPhotosPickerItems,
                    maxSelectionCount: 6,
                    matching: .any(of: [.images, .videos, .livePhotos, .slomoVideos]),
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customPickedMediaItems.isEmpty ? "Choose Photos / Videos" : "Add More Photos / Videos")
                                .font(.system(size: 13, weight: .bold))
                            Text("Access Camera Roll, live photos, or clips")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.silver)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.silver)
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.hairline, lineWidth: 1)
                    )
                }
            }

            // Preview thumbnails of loaded items
            if !customPickedMediaItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(customPickedMediaItems.enumerated()), id: \.element.id) { idx, item in
                            ZStack(alignment: .topTrailing) {
                                if let imgData = item.customImageData, let uiImg = UIImage(data: imgData) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.surfaceRaised)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Image(systemName: item.isVideo ? "video.fill" : "photo")
                                                .foregroundColor(AppTheme.primary)
                                        )
                                }

                                Button {
                                    customPickedMediaItems.remove(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .background(Color.black.clipShape(Circle()))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - On-Image Text Overlay Quick Tool
    private var imageTextEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "textformat")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                    Text("Text on Image")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    showTextEditorModal = true
                } label: {
                    Text(imageOverlayText.isEmpty ? "Add Text" : "Edit Text")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
            }

            if !imageOverlayText.isEmpty {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(imageOverlayText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Text("Font: \(overlayFontStyle)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.silver)

                            Circle()
                                .fill(Color(hex: overlayColorHex))
                                .frame(width: 10, height: 10)

                            Text(overlayHasBackground ? "Boxed" : "Transparent")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.silver)
                        }
                    }

                    Spacer()

                    Button {
                        imageOverlayText = ""
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .padding(12)
                .background(AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    showTextEditorModal = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "character.textbox")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add On-Screen Text / Sticker")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Overlay custom text directly onto your photo")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.silver)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(12)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - On-Image Text Customizer Modal Sheet
    private var onImageTextCustomizerSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Live Preview of text
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.surfaceRaised)
                                .frame(height: 140)

                            if !imageOverlayText.isEmpty {
                                Text(imageOverlayText)
                                    .font(fontForStyle(overlayFontStyle))
                                    .foregroundColor(Color(hex: overlayColorHex))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        overlayHasBackground
                                            ? Color.black.opacity(0.75)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 2)
                            } else {
                                Text("Type text below...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.silver)
                            }
                        }

                        // Text Field Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Text Content")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)

                            TextField("Enter text for your image...", text: $imageOverlayText)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(AppTheme.surfaceRaised)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Font Style Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Typography Style")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                ForEach(fontStyles, id: \.self) { style in
                                    Button {
                                        overlayFontStyle = style
                                    } label: {
                                        Text(style)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(overlayFontStyle == style ? .black : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(overlayFontStyle == style ? AppTheme.primary : AppTheme.surfaceRaised)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Color Palette
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Text Color")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ForEach(availableColors, id: \.self) { hex in
                                    Button {
                                        overlayColorHex = hex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Circle()
                                                    .stroke(overlayColorHex == hex ? AppTheme.primary : Color.white.opacity(0.3), lineWidth: overlayColorHex == hex ? 3 : 1)
                                            )
                                    }
                                }
                            }
                        }

                        // Background Box Toggle & Position
                        VStack(spacing: 14) {
                            Toggle("Background Box Overlay", isOn: $overlayHasBackground)
                                .font(.system(size: 14, weight: .semibold))
                                .tint(AppTheme.primary)

                            Divider().background(AppTheme.hairline)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Position on Image")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)

                                Picker("Position", selection: $overlayPosition) {
                                    Text("Top").tag(-0.8)
                                    Text("Center").tag(0.0)
                                    Text("Bottom").tag(0.8)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(14)
                        .background(AppTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button {
                            showTextEditorModal = false
                        } label: {
                            Text("Done")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Text to Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showTextEditorModal = false
                    }
                    .foregroundColor(AppTheme.silver)
                }
            }
        }
    }

    private func fontForStyle(_ style: String) -> Font {
        switch style {
        case "Heavy":
            return .system(size: 20, weight: .black, design: .default)
        case "Modern":
            return .system(size: 18, weight: .bold, design: .rounded)
        case "Neon":
            return .system(size: 19, weight: .black, design: .monospaced)
        case "Typewriter":
            return .system(size: 17, weight: .medium, design: .serif)
        case "Minimal":
            return .system(size: 16, weight: .semibold, design: .default)
        default:
            return .system(size: 18, weight: .bold)
        }
    }

    // MARK: - Music Attachment Bar & Audio Preview
    private var musicAttachmentBar: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                    Text("Soundtrack (Apple Music & Spotify)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    showMusicPicker = true
                } label: {
                    Text(selectedAudioTrack == nil ? "Add Music" : "Change Song")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
            }

            if let audio = selectedAudioTrack {
                HStack(spacing: 12) {
                    // Play / Pause Button with live preview audio engine
                    Button {
                        AudioPreviewEngine.shared.togglePlayPause(for: audio)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(audio.platform.brandColor.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: AudioPreviewEngine.shared.currentlyPlayingTrack?.id == audio.id && AudioPreviewEngine.shared.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(audio.platform.brandColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(audio.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Image(systemName: audio.platform.iconName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(audio.platform.brandColor)
                        }

                        Text("\(audio.artist) · \(audio.bpm) BPM")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.silver)

                        // Live audio equalizer bar when playing
                        if AudioPreviewEngine.shared.currentlyPlayingTrack?.id == audio.id && AudioPreviewEngine.shared.isPlaying {
                            HStack(spacing: 2) {
                                ForEach(0..<AudioPreviewEngine.shared.audioWaveformAmplitudes.count, id: \.self) { barIdx in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(audio.platform.brandColor)
                                        .frame(width: 3, height: 12 * AudioPreviewEngine.shared.audioWaveformAmplitudes[barIdx])
                                        .animation(.easeInOut(duration: 0.1), value: AudioPreviewEngine.shared.audioWaveformAmplitudes[barIdx])
                                }
                                Text("Previewing Sound...")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(audio.platform.brandColor)
                                    .padding(.leading, 4)
                            }
                            .padding(.top, 2)
                        }
                    }

                    Spacer()

                    Button {
                        AudioPreviewEngine.shared.stop()
                        selectedAudioTrack = nil
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.silver)
                    }
                }
                .padding(12)
                .background(AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    showMusicPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Attach Apple Music or Spotify Track")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("Hear song previews before applying")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.silver)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.silver)
                    }
                    .padding(12)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Caption Input
    private var captionInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)

            TextField("Write a caption...", text: $caption, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .frame(minHeight: 80, alignment: .topLeading)
                .background(AppTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                )
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Photos & Video Loading Logic
    private func loadPickedMediaItems(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isLoadingMedia = true

        Task {
            var loaded: [PostMediaItem] = []

            for (index, item) in items.enumerated() {
                // Try loading image data
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let media = PostMediaItem(
                        id: "device_media_\(UUID().uuidString)",
                        title: "Media \(index + 1)",
                        iconName: "photo.fill",
                        subtitle: nil,
                        isVideo: false,
                        customImageData: data
                    )
                    loaded.append(media)
                }
            }

            await MainActor.run {
                if !loaded.isEmpty {
                    self.customPickedMediaItems = loaded
                }
                self.isLoadingMedia = false
            }
        }
    }

    // MARK: - Publish Action
    private func publishPost() {
        isPosting = true
        AudioPreviewEngine.shared.stop()

        let fallbackMedia = [
            PostMediaItem(
                id: UUID().uuidString,
                title: "Post",
                iconName: "photo.fill",
                gradientHexes: ["#1F1111", "#3D1A1A"],
                subtitle: nil,
                isVideo: false
            )
        ]

        let finalMedia = customPickedMediaItems.isEmpty ? fallbackMedia : customPickedMediaItems
        let finalCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "New post ⚡️"
            : caption

        let post = AthletePost(
            authorName: authorName,
            authorHandle: authorHandle,
            athleteType: athleteType,
            authorProfileImageData: authorProfileImageData,
            isPublicAuthor: isPublicAuthor,
            timeAgo: "Just now",
            workoutTag: "",
            workoutStats: "",
            caption: finalCaption,
            imageName: "photo.fill",
            mediaType: finalMedia.contains(where: { $0.isVideo }) ? .video : .photo,
            mediaItems: finalMedia,
            mediaIconName: "photo.fill",
            gradientColors: [Color(hex: "#1A1A24"), Color(hex: "#2D1B36")],
            audioTrack: selectedAudioTrack,
            videoFilter: activeFilter,
            textOverlay: imageOverlayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : imageOverlayText,
            likesCount: 1,
            isLiked: true,
            comments: []
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onPublish?(post)
            onPost?(post)
            dismiss()
        }
    }
}

// MARK: - Music Picker Modal (Listen & Hear Before Applying + Import Apple Music / Spotify)
struct MusicPickerModal: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTrack: AudioTrack?
    var onSelectTrack: (AudioTrack) -> Void

    @ObservedObject private var audioEngine = AudioPreviewEngine.shared
    @State private var selectedPlatform: MusicService = .all
    @State private var searchQuery: String = ""
    @State private var allLibraryTracks: [AudioTrack] = AudioTrack.library
    @State private var showImportDialog: Bool = false

    // Import Song Form States
    @State private var importSongTitle: String = ""
    @State private var importArtistName: String = ""
    @State private var importPlatform: MusicService = .spotify
    @State private var importBPM: Int = 140
    @State private var importWorkoutTag: String = "Gym Vibe"

    var filteredTracks: [AudioTrack] {
        allLibraryTracks.filter { track in
            let matchesPlatform = (selectedPlatform == .all) || (track.platform == selectedPlatform)
            let matchesSearch = searchQuery.isEmpty
                || track.title.localizedCaseInsensitiveContains(searchQuery)
                || track.artist.localizedCaseInsensitiveContains(searchQuery)
                || track.workoutTag.localizedCaseInsensitiveContains(searchQuery)
            return matchesPlatform && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Platform Filter Chips
                    HStack(spacing: 8) {
                        ForEach([MusicService.all, MusicService.spotify, MusicService.appleMusic]) { platform in
                            Button {
                                selectedPlatform = platform
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: platform.iconName)
                                        .font(.system(size: 12, weight: .bold))
                                    Text(platform.rawValue)
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(selectedPlatform == platform ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedPlatform == platform ? platform.brandColor : AppTheme.surfaceRaised)
                                .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.silver)
                        TextField("Search artist, track title, or vibe...", text: $searchQuery)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.silver)
                            }
                        }
                    }
                    .padding(12)
                    .background(AppTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    // Import Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Missing a song from Apple Music or Spotify?")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Import any track or playlist link instantly")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.silver)
                        }

                        Spacer()

                        Button {
                            showImportDialog = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Import Song")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Song List
                    List {
                        ForEach(filteredTracks) { track in
                            songRow(track)
                                .listRowBackground(AppTheme.surface)
                                .listRowSeparatorTint(AppTheme.hairline)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    // Bottom Floating Preview Player (if audio is actively previewing)
                    if let playingTrack = audioEngine.currentlyPlayingTrack {
                        activePreviewPlayerBottomBar(playingTrack)
                    }
                }
            }
            .navigationTitle("Music Soundtracks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        audioEngine.stop()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.silver)
                }
            }
            .sheet(isPresented: $showImportDialog) {
                importSongSheet
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Song Row with Audio Preview
    private func songRow(_ track: AudioTrack) -> some View {
        HStack(spacing: 12) {
            // Play / Listen Preview Button
            Button {
                audioEngine.togglePlayPause(for: track)
            } label: {
                ZStack {
                    Circle()
                        .fill(track.platform.brandColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: audioEngine.currentlyPlayingTrack?.id == track.id && audioEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(track.platform.brandColor)
                }
            }
            .buttonStyle(.plain)

            // Song Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Image(systemName: track.platform.iconName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(track.platform.brandColor)
                }

                HStack(spacing: 6) {
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.silver)

                    Text("·")
                        .foregroundColor(AppTheme.silver)

                    Text("\(track.bpm) BPM")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
            }

            Spacer()

            // Apply Button
            Button {
                audioEngine.stop()
                onSelectTrack(track)
            } label: {
                Text(selectedTrack?.id == track.id ? "Applied" : "Apply")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(selectedTrack?.id == track.id ? .black : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedTrack?.id == track.id ? AppTheme.primary : AppTheme.surfaceRaised)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Active Preview Player Bottom Bar
    private func activePreviewPlayerBottomBar(_ track: AudioTrack) -> some View {
        VStack(spacing: 6) {
            // Waveform Amplitude visualization
            HStack(spacing: 3) {
                ForEach(0..<audioEngine.audioWaveformAmplitudes.count, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(track.platform.brandColor)
                        .frame(width: 4, height: max(4, 20 * audioEngine.audioWaveformAmplitudes[idx]))
                        .animation(.easeInOut(duration: 0.08), value: audioEngine.audioWaveformAmplitudes[idx])
                }
                Spacer()
                Text("LIVE AUDIO PREVIEW")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(track.platform.brandColor)
                    .tracking(1)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button {
                    audioEngine.togglePlayPause(for: track)
                } label: {
                    Image(systemName: audioEngine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(track.platform.brandColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.silver)
                }

                Spacer()

                Button {
                    audioEngine.stop()
                    onSelectTrack(track)
                } label: {
                    Text("Apply to Post")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
        .background(AppTheme.surfaceRaised)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.hairline),
            alignment: .top
        )
    }

    // MARK: - Import Songs from Apple Music / Spotify Sheet
    private var importSongSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.ground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Service selector
                        Picker("Platform", selection: $importPlatform) {
                            Text("Spotify").tag(MusicService.spotify)
                            Text("Apple Music").tag(MusicService.appleMusic)
                        }
                        .pickerStyle(.segmented)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Song Title")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.silver)
                                Spacer()
                                TextField("e.g. Lose Yourself", text: $importSongTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                            }

                            Divider().background(AppTheme.hairline)

                            HStack {
                                Text("Artist Name")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.silver)
                                Spacer()
                                TextField("e.g. Eminem", text: $importArtistName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                            }

                            Divider().background(AppTheme.hairline)

                            HStack {
                                Text("Tempo (BPM)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.silver)
                                Spacer()
                                Stepper("\(importBPM) BPM", value: $importBPM, in: 70...200, step: 5)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(14)
                        .background(AppTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Quick Import Preset Templates
                        VStack(alignment: .leading, spacing: 10) {
                            Text("One-Tap Popular Streaming Imports")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)

                            ForEach([
                                ("Till I Collapse", "Eminem", MusicService.spotify, 171, "High Energy"),
                                ("Superhero (Heroes & Villains)", "Metro Boomin", MusicService.appleMusic, 117, "Beats"),
                                ("Levitating", "Dua Lipa", MusicService.spotify, 103, "Pop"),
                                ("GigaChad Theme", "Phonk Nation", MusicService.appleMusic, 130, "Phonk")
                            ], id: \.0) { title, artist, platform, bpm, tag in
                                Button {
                                    importSongTitle = title
                                    importArtistName = artist
                                    importPlatform = platform
                                    importBPM = bpm
                                    importWorkoutTag = tag
                                } label: {
                                    HStack {
                                        Image(systemName: platform.iconName)
                                            .foregroundColor(platform.brandColor)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(title)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("\(artist) · \(bpm) BPM")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.silver)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(AppTheme.primary)
                                    }
                                    .padding(10)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        Button {
                            guard !importSongTitle.isEmpty, !importArtistName.isEmpty else { return }
                            let newTrack = AudioTrack(
                                id: "custom_\(UUID().uuidString)",
                                title: importSongTitle,
                                artist: importArtistName,
                                platform: importPlatform,
                                durationSeconds: 210,
                                bpm: importBPM,
                                energyScore: 0.95,
                                coverGradient: ["#1F1A24", "#3D2B4A"],
                                isPopularInSolxce: true,
                                workoutTag: importWorkoutTag,
                                previewAudioFrequency: Double.random(in: 440...620),
                                isUserImported: true
                            )
                            allLibraryTracks.insert(newTrack, at: 0)
                            showImportDialog = false
                            audioEngine.playTrackPreview(newTrack)
                        } label: {
                            Text("Import to Music Library")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(importSongTitle.isEmpty || importArtistName.isEmpty ? AppTheme.silver.opacity(0.4) : AppTheme.primary)
                                .clipShape(Capsule())
                        }
                        .disabled(importSongTitle.isEmpty || importArtistName.isEmpty)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Import from Streaming")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showImportDialog = false
                    }
                    .foregroundColor(AppTheme.silver)
                }
            }
        }
    }
}
