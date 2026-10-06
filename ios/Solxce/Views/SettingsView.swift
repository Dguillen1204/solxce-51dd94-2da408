// Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("solxce_bundle_id") private var bundleID = "com.solxce.app"
    @ObservedObject private var socialManager = SocialPrivacyManager.shared

    @State private var showingPrivacySheet = false
    @State private var showingDirectMessages = false

    var body: some View {
        NavigationStack {
            List {
                // Social & Privacy Settings Link
                Section(header: Text("Social & Safety").foregroundStyle(AppTheme.textSecondary)) {
                    Button {
                        showingPrivacySheet = true
                    } label: {
                        HStack {
                            Label("Privacy & Safety Rules", systemImage: "hand.raised.shield.fill")
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            if socialManager.isPrivateAccount {
                                Text("Private")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Button {
                        showingDirectMessages = true
                    } label: {
                        HStack {
                            Label("Direct Messages", systemImage: "bubble.left.and.bubble.right.fill")
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            Text("\(socialManager.conversations.count)")
                                .font(AppTheme.headlineFont)
                                .foregroundStyle(AppTheme.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    HStack {
                        Label("Blocked Accounts", systemImage: "person.crop.circle.badge.xmark")
                            .foregroundStyle(AppTheme.primary)
                        Spacer()
                        Text("\(socialManager.blockedHandles.count)")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .listRowBackground(AppTheme.surface)

                // App & System Configuration
                Section(header: Text("App Configuration").foregroundStyle(AppTheme.textSecondary)) {
                    HStack {
                        Text("Bundle Identifier")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primary)
                        Spacer()
                        Text(bundleID)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                    }

                    HStack {
                        Text("Version")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primary)
                        Spacer()
                        Text("1.0.0 (Release Ready)")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }
            .sheet(isPresented: $showingPrivacySheet) {
                PrivacyAndSecurityView()
            }
            .sheet(isPresented: $showingDirectMessages) {
                DirectMessagesListView()
            }
        }
    }
}
