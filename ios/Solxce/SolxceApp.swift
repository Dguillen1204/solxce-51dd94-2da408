// SolxceApp.swift
import SwiftUI
import SwiftData

@main
struct SolxceApp: App {
    @AppStorage("solxce_app_appearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    @AppStorage(AppTheme.activeAccentKey) private var selectedAccentRaw: String = AppAccentColor.volt.rawValue

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    private var currentAccent: AppAccentColor {
        AppAccentColor(rawValue: selectedAccentRaw) ?? .volt
    }

    init() {
        // Configure standard tab bar appearance with initial active theme accent
        let activeAccent = AppTheme.activeAccent
        SolxceApp.configureTabBarAppearance(with: activeAccent.color)
    }

    public static func configureTabBarAppearance(with accentColor: Color) {
        let uiColor = UIColor(accentColor)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0A0A0C"))
        appearance.shadowColor = UIColor(Color.white.opacity(0.12)) // subtle hairline top border
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.white.opacity(0.45))
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: uiColor
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.45))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = uiColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.45))
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.inlineLayoutAppearance.selected.iconColor = uiColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.45))
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.compactInlineLayoutAppearance.selected.iconColor = uiColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    updateTabBarControllers(window.rootViewController, appearance: appearance, tintColor: uiColor)
                }
            }
        }
    }

    private static func updateTabBarControllers(_ root: UIViewController?, appearance: UITabBarAppearance, tintColor: UIColor) {
        guard let root = root else { return }
        if let tab = root as? UITabBarController {
            tab.tabBar.standardAppearance = appearance
            tab.tabBar.scrollEdgeAppearance = appearance
            tab.tabBar.tintColor = tintColor
        }
        for child in root.children {
            updateTabBarControllers(child, appearance: appearance, tintColor: tintColor)
        }
        if let presented = root.presentedViewController {
            updateTabBarControllers(presented, appearance: appearance, tintColor: tintColor)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentAppearance.colorScheme)
                .onChange(of: selectedAccentRaw) { _, newRaw in
                    let newAccent = AppAccentColor(rawValue: newRaw) ?? .volt
                    SolxceApp.configureTabBarAppearance(with: newAccent.color)
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
            SolxceApp.configureTabBarAppearance(with: currentAccent.color)
            SeedDataManager.seedIfNeeded(context: modelContext)
            if !hasCompletedSignup {
                showSignUpSheet = true
            }
        }
        .onChange(of: selectedAccentRaw) { _, newRaw in
            let newAccent = AppAccentColor(rawValue: newRaw) ?? .volt
            SolxceApp.configureTabBarAppearance(with: newAccent.color)
        }
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
