// Models/SubscriptionManager.swift
import SwiftUI
import Combine
import PassKit

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

    var priceNumeric: Double {
        switch self {
        case .monthly: return 4.99
        case .annual: return 49.99
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

    var postTrialChargeText: String {
        switch self {
        case .monthly: return "$4.99/month"
        case .annual: return "$49.99/year"
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

enum PaymentMethodType: String, CaseIterable {
    case applePay = "Apple Pay"
    case creditCard = "Credit Card"
    case inAppPurchase = "In-App Purchase"
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @AppStorage("solxce_is_pro_active") var isPro: Bool = false
    @AppStorage("solxce_active_plan") var activePlanRaw: String = SubscriptionPlanTier.annual.rawValue
    @AppStorage("solxce_subscription_start_date") var subscriptionStartTimestamp: Double = 0
    @AppStorage("solxce_is_in_trial") var isInTrial: Bool = false
    @AppStorage("solxce_trial_end_date") var trialEndTimestamp: Double = 0
    @AppStorage("solxce_payment_method") var paymentMethodRaw: String = PaymentMethodType.applePay.rawValue

    @Published var selectedPlan: SubscriptionPlanTier = .annual
    @Published var isPurchasing: Bool = false
    @Published var purchaseSuccessToast: Bool = false
    @Published var applePaySheetPresented: Bool = false
    @Published var lastErrorMessage: String? = nil

    var activePlan: SubscriptionPlanTier {
        get { SubscriptionPlanTier(rawValue: activePlanRaw) ?? .annual }
        set { activePlanRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethodType {
        get { PaymentMethodType(rawValue: paymentMethodRaw) ?? .applePay }
        set { paymentMethodRaw = newValue.rawValue }
    }

    /// Calculated date when the 7-day free trial will end and the customer will be automatically charged
    var trialEndDate: Date {
        if trialEndTimestamp > 0 {
            return Date(timeIntervalSince1970: trialEndTimestamp)
        }
        return Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }

    var daysRemainingInTrial: Int {
        guard isInTrial else { return 0 }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, remaining)
    }

    var trialBillingFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: trialEndDate)
    }

    /// Checks if device supports Apple Pay
    var isApplePayAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    /// Purchase with Apple Pay or native StoreKit subscription
    func startTrialWithApplePay(plan: SubscriptionPlanTier) async -> Bool {
        isPurchasing = true
        paymentMethod = .applePay

        // Simulate Apple Pay sheet biometric authorization and tokenization
        try? await Task.sleep(nanoseconds: 750_000_000)

        isPro = true
        activePlan = plan
        isInTrial = true
        let now = Date()
        subscriptionStartTimestamp = now.timeIntervalSince1970
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        trialEndTimestamp = sevenDaysLater.timeIntervalSince1970

        isPurchasing = false
        purchaseSuccessToast = true
        return true
    }

    func purchase(plan: SubscriptionPlanTier, withTrial: Bool = true, method: PaymentMethodType = .applePay) async {
        isPurchasing = true
        paymentMethod = method
        try? await Task.sleep(nanoseconds: 600_000_000)

        isPro = true
        activePlan = plan
        let now = Date()
        subscriptionStartTimestamp = now.timeIntervalSince1970

        if withTrial {
            isInTrial = true
            let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
            trialEndTimestamp = sevenDaysLater.timeIntervalSince1970
        } else {
            isInTrial = false
            trialEndTimestamp = 0
        }

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
        isInTrial = false
        subscriptionStartTimestamp = 0
        trialEndTimestamp = 0
    }
}
