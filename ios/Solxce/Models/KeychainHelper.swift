// Models/KeychainHelper.swift
import Foundation
import Security

/// Lightweight and secure keychain manager for storing user authentication credentials and passwords.
public enum KeychainHelper {
    private static let serviceName = "app.solxce.credentials"
    private static let passwordKey = "user_account_password"
    private static let hasPasswordFlagKey = "solxce_has_account_password"

    public static func savePassword(_ password: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }

        // Remove old entry if exists
        deletePassword()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passwordKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            UserDefaults.standard.set(true, forKey: hasPasswordFlagKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "solxce_password_last_updated")
            return true
        }
        return false
    }

    public static func getPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passwordKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    public static func hasPassword() -> Bool {
        if UserDefaults.standard.bool(forKey: hasPasswordFlagKey) {
            return true
        }
        return getPassword() != nil
    }

    public static func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: passwordKey
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: hasPasswordFlagKey)
        UserDefaults.standard.removeObject(forKey: "solxce_password_last_updated")
    }

    public static func lastUpdatedString() -> String {
        let timestamp = UserDefaults.standard.double(forKey: "solxce_password_last_updated")
        guard timestamp > 0 else {
            return hasPassword() ? "Protected" : "No password set"
        }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
