// Models/MediaAndAudioModels.swift
import Foundation
import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Post Media Type
public enum PostMediaType: String, Codable, CaseIterable {
    case photo = "Photos"
    case video = "Video / Reel"

    public var iconName: String {
        switch self {
        case .photo: return "square.stack.3d.forward.dottedline.fill"
        case .video: return "video.fill"
        }
    }
}

// MARK: - Singular Media Item for Multi-Picture Carousels & Video
public struct PostMediaItem: Identifiable, Hashable, Codable {
    public let id: String
    public var title: String
    public var iconName: String
    public var gradientHexes: [String]
    public var subtitle: String?
    public var isVideo: Bool
    public var customImageData: Data? // Local device image data from camera roll or camera
    public var videoDurationSeconds: Double? // For user captured/picked videos

    public init(
        id: String = UUID().uuidString,
        title: String,
        iconName: String,
        gradientHexes: [String] = ["#1A1A24", "#2D1B36"],
        subtitle: String? = nil,
        isVideo: Bool = false,
        customImageData: Data? = nil,
        videoDurationSeconds: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.gradientHexes = gradientHexes
        self.subtitle = subtitle
        self.isVideo = isVideo
        self.customImageData = customImageData
        self.videoDurationSeconds = videoDurationSeconds
    }

    public var gradientColors: [Color] {
        gradientHexes.map { hex in
            Color(hex: hex)
        }
    }
}

// MARK: - Streaming Platform Source
public enum MusicService: String, Codable, CaseIterable, Identifiable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case all = "All Platforms"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .appleMusic: return "apple.logo"
        case .spotify: return "waveform.circle.fill"
        case .all: return "music.note.list"
        }
    }

    public var brandColor: Color {
        switch self {
        case .appleMusic: return Color(red: 0.98, green: 0.22, blue: 0.35) // Apple Music Red/Pink
        case .spotify: return Color(red: 0.11, green: 0.84, blue: 0.38)    // Spotify Green
        case .all: return Color(red: 0.80, green: 1.0, blue: 0.0)         // Athletic Volt
        }
    }
}

// MARK: - Music Artist Model
public struct MusicArtist: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let genre: String
    public let monthlyListeners: String
    public let avatarIcon: String
    public let gradientColors: [String]
    public let isVerified: Bool

    public static let artists: [MusicArtist] = [
        MusicArtist(
            id: "drake",
            name: "Drake",
            genre: "Hip-Hop / Rap",
            monthlyListeners: "82.4M",
            avatarIcon: "person.crop.circle.fill",
            gradientColors: ["#1F1A24", "#3D2B4A"],
            isVerified: true
        ),
        MusicArtist(
            id: "travis",
            name: "Travis Scott",
            genre: "Trap / Psychedelic Rap",
            monthlyListeners: "68.9M",
            avatarIcon: "flame.circle.fill",
            gradientColors: ["#2B1A0E", "#523218"],
            isVerified: true
        ),
        MusicArtist(
            id: "kanye",
            name: "Kanye West",
            genre: "Hip-Hop / Production",
            monthlyListeners: "64.1M",
            avatarIcon: "sparkles.circle.fill",
            gradientColors: ["#1C1C1C", "#383838"],
            isVerified: true
        ),
        MusicArtist(
            id: "weeknd",
            name: "The Weeknd",
            genre: "R&B / Synth-Pop",
            monthlyListeners: "108.2M",
            avatarIcon: "moon.stars.circle.fill",
            gradientColors: ["#2B0E14", "#541B26"],
            isVerified: true
        ),
        MusicArtist(
            id: "dvrst",
            name: "DVRST",
            genre: "Phonk / Drift",
            monthlyListeners: "14.6M",
            avatarIcon: "bolt.circle.fill",
            gradientColors: ["#0E232B", "#184452"],
            isVerified: true
        ),
        MusicArtist(
            id: "tevez",
            name: "Tevez",
            genre: "Hardstyle / Gym Phonk",
            monthlyListeners: "9.3M",
            avatarIcon: "figure.strengthtraining.traditional",
            gradientColors: ["#2B1F0E", "#523C18"],
            isVerified: true
        )
    ]
}

// MARK: - Audio Track Model
public struct AudioTrack: Identifiable, Hashable, Codable {
    public let id: String
    public let title: String
    public let artist: String
    public let platform: MusicService
    public let durationSeconds: Double
    public let bpm: Int
    public let energyScore: Double // 0.0 - 1.0 (workout hype factor)
    public let coverGradient: [String]
    public let isPopularInSolxce: Bool
    public let workoutTag: String // "Heavy PR", "Tempo Run", "HIIT", "Zone 2"
    public var previewAudioFrequency: Double = 440.0 // Base pitch for audio preview engine
    public var isUserImported: Bool = false

    public var formattedDuration: String {
        let mins = Int(durationSeconds) / 60
        let secs = Int(durationSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public static let initialLibrary: [AudioTrack] = [
        // Drake
        AudioTrack(
            id: "drake_first_person",
            title: "First Person Shooter",
            artist: "Drake ft. J. Cole",
            platform: .appleMusic,
            durationSeconds: 247,
            bpm: 164,
            energyScore: 0.94,
            coverGradient: ["#1F1A24", "#3D2B4A"],
            isPopularInSolxce: true,
            workoutTag: "Heavy PR",
            previewAudioFrequency: 520.0
        ),
        AudioTrack(
            id: "drake_gods_plan",
            title: "God's Plan",
            artist: "Drake",
            platform: .spotify,
            durationSeconds: 198,
            bpm: 154,
            energyScore: 0.88,
            coverGradient: ["#1F1A24", "#3D2B4A"],
            isPopularInSolxce: true,
            workoutTag: "Tempo Run",
            previewAudioFrequency: 440.0
        ),
        AudioTrack(
            id: "drake_knife_talk",
            title: "Knife Talk",
            artist: "Drake ft. 21 Savage",
            platform: .appleMusic,
            durationSeconds: 243,
            bpm: 146,
            energyScore: 0.92,
            coverGradient: ["#1F1A24", "#3D2B4A"],
            isPopularInSolxce: false,
            workoutTag: "Deadlift Set",
            previewAudioFrequency: 390.0
        ),
        AudioTrack(
            id: "drake_rich_flex",
            title: "Rich Flex",
            artist: "Drake & 21 Savage",
            platform: .appleMusic,
            durationSeconds: 239,
            bpm: 150,
            energyScore: 0.95,
            coverGradient: ["#1F1A24", "#4A2B4A"],
            isPopularInSolxce: true,
            workoutTag: "Bench Max",
            previewAudioFrequency: 480.0
        ),

        // Travis Scott
        AudioTrack(
            id: "travis_fein",
            title: "FE!N",
            artist: "Travis Scott ft. Playboi Carti",
            platform: .spotify,
            durationSeconds: 191,
            bpm: 148,
            energyScore: 0.98,
            coverGradient: ["#2B1A0E", "#523218"],
            isPopularInSolxce: true,
            workoutTag: "Hype / PR",
            previewAudioFrequency: 560.0
        ),
        AudioTrack(
            id: "travis_sicko_mode",
            title: "SICKO MODE",
            artist: "Travis Scott ft. Drake",
            platform: .appleMusic,
            durationSeconds: 312,
            bpm: 155,
            energyScore: 0.96,
            coverGradient: ["#2B1A0E", "#523218"],
            isPopularInSolxce: true,
            workoutTag: "Max Effort",
            previewAudioFrequency: 490.0
        ),
        AudioTrack(
            id: "travis_my_eyes",
            title: "MY EYES",
            artist: "Travis Scott",
            platform: .spotify,
            durationSeconds: 251,
            bpm: 130,
            energyScore: 0.85,
            coverGradient: ["#2B1A0E", "#523218"],
            isPopularInSolxce: false,
            workoutTag: "Running Flow",
            previewAudioFrequency: 420.0
        ),
        AudioTrack(
            id: "travis_goosebumps",
            title: "Goosebumps",
            artist: "Travis Scott ft. Kendrick Lamar",
            platform: .spotify,
            durationSeconds: 243,
            bpm: 130,
            energyScore: 0.93,
            coverGradient: ["#2B100E", "#592015"],
            isPopularInSolxce: true,
            workoutTag: "Squat Double",
            previewAudioFrequency: 460.0
        ),

        // Gym Phonk / Hardstyle
        AudioTrack(
            id: "dvrst_close_eyes",
            title: "Close Eyes",
            artist: "DVRST",
            platform: .spotify,
            durationSeconds: 132,
            bpm: 135,
            energyScore: 0.99,
            coverGradient: ["#0E232B", "#184452"],
            isPopularInSolxce: true,
            workoutTag: "Gym Phonk PR",
            previewAudioFrequency: 600.0
        ),
        AudioTrack(
            id: "giga_chad_theme",
            title: "Can You Feel My Heart (Phonk Remix)",
            artist: "Bring Me The Horizon / Phonk",
            platform: .appleMusic,
            durationSeconds: 150,
            bpm: 140,
            energyScore: 0.97,
            coverGradient: ["#2B0E0E", "#521818"],
            isPopularInSolxce: true,
            workoutTag: "Squat Double",
            previewAudioFrequency: 540.0
        ),
        AudioTrack(
            id: "tevez_hardstyle",
            title: "Hardstyle Overload",
            artist: "Tevez",
            platform: .spotify,
            durationSeconds: 168,
            bpm: 150,
            energyScore: 0.99,
            coverGradient: ["#2B1F0E", "#523C18"],
            isPopularInSolxce: false,
            workoutTag: "Pre-Workout Max",
            previewAudioFrequency: 640.0
        ),
        AudioTrack(
            id: "brazilian_phonk",
            title: "Montagem Diamante Rosa",
            artist: "DJ Topo & Mc Henny",
            platform: .spotify,
            durationSeconds: 124,
            bpm: 132,
            energyScore: 0.98,
            coverGradient: ["#2B0E27", "#52184B"],
            isPopularInSolxce: true,
            workoutTag: "Cardio Blitz",
            previewAudioFrequency: 580.0
        ),

        // Kanye & Weeknd
        AudioTrack(
            id: "kanye_carnival",
            title: "CARNIVAL",
            artist: "¥$, Kanye West, Ty Dolla $ign",
            platform: .appleMusic,
            durationSeconds: 264,
            bpm: 148,
            energyScore: 0.96,
            coverGradient: ["#1C1C1C", "#383838"],
            isPopularInSolxce: true,
            workoutTag: "Chest PR",
            previewAudioFrequency: 500.0
        ),
        AudioTrack(
            id: "kanye_stronger",
            title: "Stronger",
            artist: "Kanye West",
            platform: .appleMusic,
            durationSeconds: 311,
            bpm: 123,
            energyScore: 0.97,
            coverGradient: ["#29180D", "#5E341B"],
            isPopularInSolxce: true,
            workoutTag: "Leg Day Peak",
            previewAudioFrequency: 510.0
        ),
        AudioTrack(
            id: "weeknd_blinding_lights",
            title: "Blinding Lights",
            artist: "The Weeknd",
            platform: .appleMusic,
            durationSeconds: 200,
            bpm: 171,
            energyScore: 0.91,
            coverGradient: ["#2B0E14", "#541B26"],
            isPopularInSolxce: true,
            workoutTag: "10K Tempo",
            previewAudioFrequency: 450.0
        ),
        AudioTrack(
            id: "weeknd_starboy",
            title: "Starboy",
            artist: "The Weeknd ft. Daft Punk",
            platform: .spotify,
            durationSeconds: 230,
            bpm: 186,
            energyScore: 0.89,
            coverGradient: ["#2B0E14", "#541B26"],
            isPopularInSolxce: false,
            workoutTag: "Zone-2 Cardio",
            previewAudioFrequency: 430.0
        ),

        // Extra Popular Workout Tracks
        AudioTrack(
            id: "eminem_till_i_collapse",
            title: "'Till I Collapse",
            artist: "Eminem ft. Nate Dogg",
            platform: .spotify,
            durationSeconds: 297,
            bpm: 171,
            energyScore: 0.99,
            coverGradient: ["#1A1A1A", "#3D3D3D"],
            isPopularInSolxce: true,
            workoutTag: "Heavy Deadlift",
            previewAudioFrequency: 470.0
        ),
        AudioTrack(
            id: "dua_lipa_physical",
            title: "Physical",
            artist: "Dua Lipa",
            platform: .appleMusic,
            durationSeconds: 193,
            bpm: 148,
            energyScore: 0.93,
            coverGradient: ["#240E2B", "#491857"],
            isPopularInSolxce: true,
            workoutTag: "HIIT Intervals",
            previewAudioFrequency: 530.0
        )
    ]

    public static var library: [AudioTrack] {
        initialLibrary
    }
}

// MARK: - Audio Preview Service (Haptic & Synthesizer Playback Engine)
@MainActor
public final class AudioPreviewEngine: ObservableObject {
    public static let shared = AudioPreviewEngine()

    @Published public var currentlyPlayingTrack: AudioTrack? = nil
    @Published public var isPlaying: Bool = false
    @Published public var playbackProgress: Double = 0.0 // 0.0 to 1.0
    @Published public var audioWaveformAmplitudes: [CGFloat] = [0.2, 0.4, 0.7, 0.9, 0.6, 0.8, 0.3, 0.5, 0.7, 0.4]

    private var previewTimer: Timer?
    private var audioEngine: AVAudioEngine?
    private var toneNode: AVAudioSourceNode?

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if !targetEnvironment(simulator)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession setup notice: \(error.localizedDescription)")
        }
        #endif
    }

    public func togglePlayPause(for track: AudioTrack) {
        if currentlyPlayingTrack?.id == track.id && isPlaying {
            pausePreview()
        } else {
            playTrackPreview(track)
        }
    }

    public func playTrackPreview(_ track: AudioTrack) {
        stopAudioEngine()

        currentlyPlayingTrack = track
        isPlaying = true
        playbackProgress = 0.0

        // Start rhythm/melody tone engine
        startSynthesizerTone(frequency: track.previewAudioFrequency, bpm: track.bpm)

        // Run timer for interactive waveform progress and rhythm pulsing
        previewTimer?.invalidate()
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.playbackProgress += 0.02
                if self.playbackProgress >= 1.0 {
                    self.playbackProgress = 0.0
                }
                // Animate dynamic waveform bars
                self.audioWaveformAmplitudes = (0..<12).map { _ in
                    CGFloat.random(in: 0.25...1.0)
                }
            }
        }
    }

    public func pausePreview() {
        isPlaying = false
        stopAudioEngine()
        previewTimer?.invalidate()
        previewTimer = nil
    }

    public func stop() {
        currentlyPlayingTrack = nil
        isPlaying = false
        playbackProgress = 0.0
        stopAudioEngine()
        previewTimer?.invalidate()
        previewTimer = nil
    }

    private func startSynthesizerTone(frequency: Double, bpm: Int) {
        #if !targetEnvironment(simulator)
        let engine = AVAudioEngine()
        let sampleRate = 44100.0
        var phase: Double = 0.0
        let beatInterval = 60.0 / Double(max(60, bpm))

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseIncrement = (2.0 * .pi * frequency) / sampleRate

            for frame in 0..<Int(frameCount) {
                // Generate energetic synth rhythm wave
                let sampleVal = Float(sin(phase) * 0.15)
                phase += phaseIncrement
                if phase > 2.0 * .pi {
                    phase -= 2.0 * .pi
                }

                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = sampleVal
                }
            }
            return noErr
        }

        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.toneNode = sourceNode
        } catch {
            print("Audio engine error: \(error.localizedDescription)")
        }
        #endif
    }

    private func stopAudioEngine() {
        #if !targetEnvironment(simulator)
        audioEngine?.stop()
        audioEngine = nil
        toneNode = nil
        #endif
    }
}

// MARK: - Post Video Filter
public enum PostVideoFilter: String, CaseIterable, Identifiable {
    case normal = "Raw"
    case contrast = "Grit / High Contrast"
    case athleticVolt = "Solxce Volt"
    case moody = "Dark Gym"
    case goldenHour = "Sunset Runner"
    case blackAndWhite = "Monochrome Strength"

    public var id: String { rawValue }

    public var tintColor: Color {
        switch self {
        case .normal: return .clear
        case .contrast: return Color.black.opacity(0.15)
        case .athleticVolt: return AppTheme.primary.opacity(0.15)
        case .moody: return Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.2)
        case .goldenHour: return Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.15)
        case .blackAndWhite: return .white
        }
    }
}

// MARK: - Sample Video & Picture Presets for Creation
public struct MediaPreset: Identifiable {
    public let id: String
    public let title: String
    public let mediaType: PostMediaType
    public let systemIcon: String
    public let gradientColors: [Color]
    public let workoutContext: String
    public var mediaItems: [PostMediaItem] = []

    public static let defaults: [MediaPreset] = [
        MediaPreset(
            id: "carousel_bench_set",
            title: "Bench PR Carousel (3 Photos)",
            mediaType: .photo,
            systemIcon: "dumbbell.fill",
            gradientColors: [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.35, green: 0.1, blue: 0.1)],
            workoutContext: "Chest & Triceps Finisher",
            mediaItems: [
                PostMediaItem(id: "bench_1", title: "315 lbs Unrack", iconName: "dumbbell.fill", gradientHexes: ["#260D0D", "#4A1818"], subtitle: "Photo 1 of 3 · Set 3"),
                PostMediaItem(id: "bench_2", title: "Lockout & Form Path", iconName: "chart.line.uptrend.xyaxis", gradientHexes: ["#1F1111", "#3B1818"], subtitle: "Photo 2 of 3 · Clean Rep"),
                PostMediaItem(id: "bench_3", title: "Post-Set Hypertrophy", iconName: "figure.arms.open", gradientHexes: ["#241505", "#472808"], subtitle: "Photo 3 of 3 · Peak Pump")
            ]
        ),
        MediaPreset(
            id: "squat_pr_vid",
            title: "405 lbs Squat Double (Video)",
            mediaType: .video,
            systemIcon: "figure.strengthtraining.traditional",
            gradientColors: [Color(red: 0.15, green: 0.05, blue: 0.05), Color(red: 0.35, green: 0.1, blue: 0.1)],
            workoutContext: "Heavy Squat Form Check",
            mediaItems: [
                PostMediaItem(id: "squat_v1", title: "405 lbs Squat Video", iconName: "figure.strengthtraining.traditional", gradientHexes: ["#1F0E0E", "#3D1A1A"], subtitle: "4K 60fps Form Clip", isVideo: true, videoDurationSeconds: 15.0)
            ]
        ),
        MediaPreset(
            id: "tempo_run_carousel",
            title: "10K Run & Splits (3 Photos)",
            mediaType: .photo,
            systemIcon: "figure.run",
            gradientColors: [Color(red: 0.05, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.3, blue: 0.4)],
            workoutContext: "Trail Cadence 178 SPM",
            mediaItems: [
                PostMediaItem(id: "run_1", title: "Sunrise Mile 1", iconName: "figure.run", gradientHexes: ["#0B1B2B", "#163452"], subtitle: "Photo 1 of 3 · 6:58 /mi"),
                PostMediaItem(id: "run_2", title: "Heart Rate & Route", iconName: "map.fill", gradientHexes: ["#0E261D", "#1C4A39"], subtitle: "Photo 2 of 3 · Avg 158 BPM"),
                PostMediaItem(id: "run_3", title: "Finish Line 6.20 Mi", iconName: "flag.checkered", gradientHexes: ["#16253B", "#253F63"], subtitle: "Photo 3 of 3 · 44:18 Sub-45")
            ]
        )
    ]
}
