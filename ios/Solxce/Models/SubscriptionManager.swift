// Models/SubscriptionManager.swift
import SwiftUI
import Combine

enum SubscriptionPlanTier: String, CaseIterable, Identifiable {
    case monthly = "monthly"
    case annual = "annual"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "Monthly Pro"
        case .annual: return "Annual Pro"
        }
    }

    var priceString: String {
        switch self {
        case .monthly: return "$4.99 / month"
        case .annual: return "$49.99 / year"
        }
    }

    var billedAmount: String {
        switch self {
        case .monthly: return "$4.99 / month"
        case .annual: return "$49.99 / year ($4.17/mo)"
        }
    }

    var savingsBadge: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "SAVE 17%"
        }
    }

    var isMostPopular: Bool {
        self == .annual
    }
}

enum ProFeature: String, CaseIterable {
    case cameraFoodScan = "AI Camera Food Logging"
    case intermittentFasting = "Intermittent Fasting & Eating Window Alerts"
    case deepProgressReports = "In-Depth Progress Reports & AI Insights"
    case unlimitedAICoach = "Unlimited Solxce AI Coach Guidance"

    var icon: String {
        switch self {
        case .cameraFoodScan: return "camera.viewfinder"
        case .intermittentFasting: return "timer"
        case .deepProgressReports: return "chart.xyaxis.line"
        case .unlimitedAICoach: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .cameraFoodScan: return "Snap a photo of your meal to calculate macros and log calories in seconds."
        case .intermittentFasting: return "Track 16:8, 18:6, or custom fasts with automated notifications when eating windows open."
        case .deepProgressReports: return "Uncover strength volume trends, macro adherence radar, and running pace curves."
        case .unlimitedAICoach: return "Get tailored nutrition adjustments, split recommendations, and recovery advice."
        }
    }
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @AppStorage("solxce_is_pro_active") var isPro: Bool = false
    @AppStorage("solxce_active_plan") var activePlanRaw: String = SubscriptionPlanTier.annual.rawValue
    @AppStorage("solxce_subscription_start_date") var subscriptionStartTimestamp: Double = 0

    @Published var selectedPlan: SubscriptionPlanTier = .annual
    @Published var isPurchasing: Bool = false
    @Published var purchaseSuccessToast: Bool = false

    var activePlan: SubscriptionPlanTier {
        get { SubscriptionPlanTier(rawValue: activePlanRaw) ?? .annual }
        set { activePlanRaw = newValue.rawValue }
    }

    func purchase(plan: SubscriptionPlanTier) async {
        isPurchasing = true
        // Simulate quick secure StoreKit transaction
        try? await Task.sleep(nanoseconds: 600_000_000)
        isPro = true
        activePlan = plan
        subscriptionStartTimestamp = Date().timeIntervalSince1970
        isPurchasing = false
        purchaseSuccessToast = true
    }

    func restorePurchases() async -> Bool {
        isPurchasing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isPro = true
        isPurchasing = false
        return true
    }

    func cancelSubscription() {
        isPro = false
        subscriptionStartTimestamp = 0
    }
}
