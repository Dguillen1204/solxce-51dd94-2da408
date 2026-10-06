// Views/PostDetailModalSheet.swift
import SwiftUI

/// Full-screen or modal sheet showing an Instagram-style post detail from the profile grid
struct PostDetailModalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var postStore = FeedPostStore.shared
    var postID: UUID
    var onOpenReel: ((AthletePost) -> Void)? = nil

    private var currentPost: AthletePost? {
        postStore.posts.first(where: { $0.id == postID })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let post = currentPost {
                    if let index = postStore.posts.firstIndex(where: { $0.id == post.id }) {
                        VStack(spacing: 0) {
                            SimplePostCardView(
                                post: $postStore.posts[index],
                                onShare: {
                                    // Handled internally
                                },
                                onOpenReel: {
                                    onOpenReel?(post)
                                }
                            )
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Post not found")
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(AppTheme.text)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .background(AppTheme.ground.ignoresSafeArea())
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(AppAppearance(rawValue: UserDefaults.standard.string(forKey: "solxce_app_appearance") ?? "")?.colorScheme)
    }
}
