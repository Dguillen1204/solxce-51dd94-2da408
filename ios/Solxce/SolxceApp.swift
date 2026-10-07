// SolxceApp.swift
import SwiftUI
import SwiftData

@main
struct SolxceApp: App {
    @AppStorage("solxce_app_appearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue

    init() {
        // Standardize TabBar appearance with solid obsidian ground & hairline top border matching screenshot 3
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0A0A0C"))
        appearance.shadowColor = UIColor(Color.white.opacity(0.12)) // subtle hairline top border
        
        let normalItem = appearance.stackedLayoutAppearance.normal
        normalItem.iconColor = UIColor(Color.white.opacity(0.45))
        normalItem.titleTextAttributes = [.foregroundColor: UIColor(Color.white.opacity(0.45))]
        
        let selectedItem = appearance.stackedLayoutAppearance.selected
        selectedItem.iconColor = UIColor(Color(hex: "#CCFF00"))
        selectedItem.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#CCFF00"))]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(currentAppearance.colorScheme)
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

    private func updateTabBarAppearance(for accent: AppAccentColor) {
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

        // Also configure inline and compact layouts
        appearance.inlineLayoutAppearance.normal = normalItem
        appearance.inlineLayoutAppearance.selected = selectedItem
        appearance.compactInlineLayoutAppearance.normal = normalItem
        appearance.compactInlineLayoutAppearance.selected = selectedItem

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Apply immediately to existing UITabBar instances across active window scenes
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                for subview in window.subviews {
                    updateTabBarInViewHierarchy(subview, appearance: appearance, tintColor: accentUIColor)
                }
            }
        }
    }

    private func updateTabBarInViewHierarchy(_ view: UIView, appearance: UITabBarAppearance, tintColor: UIColor) {
        if let tabBar = view as? UITabBar {
            tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = appearance
            }
            tabBar.tintColor = tintColor
        }
        for subview in view.subviews {
            updateTabBarInViewHierarchy(subview, appearance: appearance, tintColor: tintColor)
        }
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
        .onAppear {
            updateTabBarAppearance(for: currentAccent)
            SeedDataManager.seedIfNeeded(context: modelContext)
            if !hasCompletedSignup {
                showSignUpSheet = true
            }
        }
        .onChange(of: selectedAccentRaw) { newRaw in
            let accent = AppAccentColor(rawValue: newRaw) ?? .volt
            updateTabBarAppearance(for: accent)
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
