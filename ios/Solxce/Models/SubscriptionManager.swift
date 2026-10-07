// Models/SubscriptionManager.swift
import SwiftUI
import Combine

/// Specific Pro Features unlocked with subscription
public enum ProFeature: String, CaseIterable, Identifiable {
    case aiMacroScanner = "AI Macro Lens & Food Scan"
    case intermittentFasting = "Intermittent Fasting Smart Alerts"
    case deepAnalytics = "Deep Recovery & GPS Telemetry"
    case customSplits = "Unlimited Split Planner & Routines"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .aiMacroScanner: return "camera.metering.matrix"
        case .intermittentFasting: return "timer"
        case .deepAnalytics: return "chart.xyaxis.line"
        case .customSplits: return "calendar.badge.clock"
        }
    }

    public var description: String {
        switch self {
        case .aiMacroScanner: return "Instant nutritional breakdown and macro calculations with camera scan."
        case .intermittentFasting: return "Autophagy timing, custom fasting windows, and smart notification alerts."
        case .deepAnalytics: return "Full GPS telemetry, heart rate zones, and detailed progress analytics."
        case .customSplits: return "Create unlimited custom workout splits, schedule days, and track volume."
        }
    }
}

/// Subscription Plan Tiers
public enum SubscriptionPlanTier: String, CaseIterable, Identifiable {
    case annual = "Annual Plan"
    case monthly = "Monthly Plan"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .annual: return "Solxce Pro (Annual)"
        case .monthly: return "Solxce Pro (Monthly)"
        }
    }

    public var billedAmount: String {
        switch self {
        case .annual: return "$49.99 / year ($4.16/mo)"
        case .monthly: return "$4.99 / month"
        }
    }

    public var savingsBadge: String? {
        switch self {
        case .annual: return "SAVE 20%"
        case .monthly: return nil
        }
    }

    public var postTrialChargeText: String {
        switch self {
        case .annual: return "$49.99/year"
        case .monthly: return "$4.99/month"
        }
    }
}

/// In-app subscription tier enumeration
public enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "Free Athlete"
    case pro = "Solxce Pro"
    case elite = "Solxce Elite"
    
    public var priceMonthly: String {
        switch self {
        case .free: return "$0/mo"
        case .pro: return "$4.99/mo"
        case .elite: return "$14.99/mo"
        }
    }
    
    public var priceYearly: String {
        switch self {
        case .free: return "$0/yr"
        case .pro: return "$49.99/yr"
        case .elite: return "$149.99/yr"
        }
    }
}

/// Standalone subscription state manager.
/// Free of PassKit or sensitive financial/payment entitlements.
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isPro: Bool = true
    @Published var isSubscribed: Bool = true
    @Published var isInTrial: Bool = false
    @Published var selectedPlan: SubscriptionPlanTier = .annual
    @Published var activePlan: SubscriptionPlanTier = .annual
    @Published var currentTier: SubscriptionTier = .pro
    @Published var isPurchasing: Bool = false
    @Published var purchaseErrorMessage: String?
    
    var trialBillingFormattedDate: String {
        let targetDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: targetDate)
    }
    
    init() {
        let savedIsPro = UserDefaults.standard.object(forKey: "solxce_is_pro") as? Bool ?? true
        self.isPro = savedIsPro
        self.isSubscribed = savedIsPro
        self.isInTrial = UserDefaults.standard.bool(forKey: "solxce_is_in_trial")
        let savedTier = UserDefaults.standard.string(forKey: "solxce_user_tier") ?? SubscriptionTier.pro.rawValue
        self.currentTier = SubscriptionTier(rawValue: savedTier) ?? .pro
    }
    
    func upgrade(to tier: SubscriptionTier) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        self.currentTier = tier
        self.isPro = (tier != .free)
        self.isSubscribed = self.isPro
        UserDefaults.standard.set(tier.rawValue, forKey: "solxce_user_tier")
        UserDefaults.standard.set(self.isPro, forKey: "solxce_is_pro")
        return true
    }
    
    func restorePurchases() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.isPro = true
        self.isSubscribed = true
        UserDefaults.standard.set(true, forKey: "solxce_is_pro")
        return true
    }
    
    func unlockProWithTrial() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.isPro = true
        self.isSubscribed = true
        self.isInTrial = true
        self.activePlan = self.selectedPlan
        UserDefaults.standard.set(true, forKey: "solxce_is_pro")
        UserDefaults.standard.set(true, forKey: "solxce_is_in_trial")
        return true
    }
}
