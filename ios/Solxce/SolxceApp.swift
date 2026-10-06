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

    @State private var selectedTab: Int = 0
    @State private var showAICoachSheet: Bool = false
    @State private var showSignUpSheet: Bool = false

    private var currentAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
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
            .tint(AppTheme.primary)

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
            SeedDataManager.seedIfNeeded(context: modelContext)
            if !hasCompletedSignup {
                showSignUpSheet = true
            }
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
                        LinearGradient(
                            colors: [
                                AppTheme.primary,
                                AppTheme.accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 10, x: 0, y: 4)

                // Sparkle / AI icon with pulse badge
                VStack(spacing: 0) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color.black)
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
                                    .stroke(AppTheme.accent, lineWidth: 1)
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
