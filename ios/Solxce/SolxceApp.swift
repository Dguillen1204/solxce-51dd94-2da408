// SolxceApp.swift
import SwiftUI
import SwiftData

@main
struct SolxceApp: App {
    @AppStorage("solxce_app_appearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage(AppTheme.activeAccentKey) private var selectedAccentRaw: String = AppAccentColor.volt.rawValue

    init() {
        // Initial setup for TabBar appearance
        let rawAccent = UserDefaults.standard.string(forKey: AppTheme.activeAccentKey) ?? AppAccentColor.volt.rawValue
        let accent = AppAccentColor(rawValue: rawAccent) ?? .volt
        SolxceApp.updateTabBarAppearance(for: accent)
    }

    public static func updateTabBarAppearance(for accent: AppAccentColor) {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0A0A0C"))
        appearance.shadowColor = UIColor(Color.white.opacity(0.12)) // subtle hairline top border
        
        let normalItem = appearance.stackedLayoutAppearance.normal
        normalItem.iconColor = UIColor(Color.white.opacity(0.45))
        normalItem.titleTextAttributes = [.foregroundColor: UIColor(Color.white.opacity(0.45))]
        
        let selectedItem = appearance.stackedLayoutAppearance.selected
        let accentUIColor = UIColor(accent.color)
        selectedItem.iconColor = accentUIColor
        selectedItem.titleTextAttributes = [.foregroundColor: accentUIColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    private var currentAccent: AppAccentColor {
        AppAccentColor(rawValue: selectedAccentRaw) ?? .volt
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentAppearance.colorScheme)
                .onAppear {
                    SolxceApp.updateTabBarAppearance(for: currentAccent)
                }
                .onChange(of: selectedAccentRaw) { newRaw in
                    let newAccent = AppAccentColor(rawValue: newRaw) ?? .volt
                    SolxceApp.updateTabBarAppearance(for: newAccent)
                }
        }
        .modelContainer(for: [
            UserProfile.self,
            WorkoutSession.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            RunEntry.self,
            FoodEntry.self,
            MacroTarget.self,
            PlannerDay.self
        ])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("solxce_has_completed_athlete_signup") private var hasCompletedSignup: Bool = false
    @AppStorage("solxce_app_appearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage(AppTheme.activeAccentKey) private var selectedAccentRaw: String = AppAccentColor.volt.rawValue
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var selectedTab: Int = 0
    @State private var showAICoachSheet: Bool = false
    @State private var showSignUpSheet: Bool = false

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    private var currentAccent: AppAccentColor {
        AppAccentColor(rawValue: selectedAccentRaw) ?? .volt
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                TodayView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Today", systemImage: "flame.fill")
                    }
                    .tag(0)

                TrainTabView()
                    .tabItem {
                        Label("Train", systemImage: "dumbbell.fill")
                    }
                    .tag(1)

                FeedView()
                    .tabItem {
                        Image("FeedCustomIcon")
                    }
                    .tag(2)

                FuelTabView()
                    .tabItem {
                        Label("Fuel", systemImage: "leaf.fill")
                    }
                    .tag(3)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
                    .tag(4)
            }
            .tint(currentAccent.color)

            // Floating AI Assistant Circle Button (Bottom Right)
            floatingAIButton
                .padding(.trailing, 16)
                .padding(.bottom, 62) // Positioned nicely above the TabBar
        }
        .overlay(alignment: .top) {
            if let banner = notificationManager.activeInAppBanner {
                inAppNotificationToast(banner: banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 54)
                    .padding(.horizontal, 16)
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: notificationManager.activeInAppBanner?.title)
        .sheet(isPresented: $showAICoachSheet) {
            AICoachChatView()
                .presentationDragIndicator(.visible)
                .preferredColorScheme(currentAppearance.colorScheme)
        }
        .fullScreenCover(isPresented: $showSignUpSheet) {
            OnboardingAthleteSignUpView(isCompleted: $hasCompletedSignup)
                .preferredColorScheme(currentAppearance.colorScheme)
        }
        .onAppear {
            SeedDataManager.seedIfNeeded(context: modelContext)
            notificationManager.checkAuthorization()
            if !hasCompletedSignup {
                showSignUpSheet = true
            }
        }
    }

    // MARK: - In-App Notification Toast Banner
    private func inAppNotificationToast(banner: NotificationManager.InAppNotificationBanner) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(banner.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: banner.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(banner.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                Text(banner.body)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                withAnimation {
                    notificationManager.activeInAppBanner = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(banner.color.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 6)
        )
    }

    // MARK: - Floating AI Circle Button
    private var floatingAIButton: some View {
        Button {
            showAICoachSheet = true
        } label: {
            ZStack {
                // Outer glow shadow ring
                Circle()
                    .fill(
                        currentAccent.gradient
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: currentAccent.color.opacity(0.45), radius: 10, x: 0, y: 4)

                // Sparkle / AI icon with pulse badge
                VStack(spacing: 0) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(currentAccent == .monochrome ? Color.white : Color.black)
                }

                // AI small sub-badge
                VStack {
                    HStack {
                        Spacer()
                        Text("AI")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(Color.black)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(currentAccent.color, lineWidth: 1)
                            )
                            .offset(x: 4, y: -4)
                    }
                    Spacer()
                }
                .frame(width: 52, height: 52)
            }
        }
        .buttonStyle(ScaleBounceButtonStyle())
        .accessibilityLabel("Ask Solxce AI Coach")
        .accessibilityHint("Opens AI chat for workout, food, and training questions")
    }
}

// MARK: - Scale Bounce Button Style
struct ScaleBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
