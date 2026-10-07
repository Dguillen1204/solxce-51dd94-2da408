// Models/SubscriptionManager.swift
import SwiftUI
import Combine

/// In-app subscription tier enumeration
public enum SubscriptionTier: String, CaseIterable, Codable {
    case free = "Free Athlete"
    case pro = "Solxce Pro"
    case elite = "Solxce Elite"
    
    public var priceMonthly: String {
        switch self {
        case .free: return "$0/mo"
        case .pro: return "$9.99/mo"
        case .elite: return "$19.99/mo"
        }
    }
    
    public var priceYearly: String {
        switch self {
        case .free: return "$0/yr"
        case .pro: return "$79.99/yr"
        case .elite: return "$149.99/yr"
        }
    }
    
    public var features: [String] {
        switch self {
        case .free:
            return ["Basic workout tracking", "Daily meal log", "Standard community feed"]
        case .pro:
            return ["Unlimited AI coaching", "Full GPS telemetry & splits", "Custom split routines", "Advanced macro scanning"]
        case .elite:
            return ["All Pro features", "1-on-1 AI athlete tuning", "Priority video rendering", "Exclusive badges & sound library"]
        }
    }
}

/// Standalone subscription state manager.
/// Free of PassKit or sensitive financial/payment entitlements.
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var currentTier: SubscriptionTier = .free
    @Published var isSubscribed: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var purchaseErrorMessage: String?
    
    init() {
        let savedTier = UserDefaults.standard.string(forKey: "solxce_user_tier") ?? SubscriptionTier.free.rawValue
        self.currentTier = SubscriptionTier(rawValue: savedTier) ?? .free
        self.isSubscribed = (self.currentTier != .free)
    }
    
    func upgrade(to tier: SubscriptionTier) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        self.currentTier = tier
        self.isSubscribed = (tier != .free)
        UserDefaults.standard.set(tier.rawValue, forKey: "solxce_user_tier")
        return true
    }
    
    func restorePurchases() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await Task.sleep(nanoseconds: 300_000_000)
        return true
    }
}
