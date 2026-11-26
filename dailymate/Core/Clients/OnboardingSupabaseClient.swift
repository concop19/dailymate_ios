//
//  OnboardingSupabaseClient.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation
import Supabase

public enum OnboardingSupabaseError: LocalizedError, Equatable, Sendable {
    case profileLimitReached

    public var errorDescription: String? {
        switch self {
        case .profileLimitReached:
            return "Mỗi tài khoản chỉ tạo được tối đa 5 hồ sơ. Bạn hãy xoá bớt một hồ sơ rồi thử lại nhé."
        }
    }
}

@DependencyClient
public struct OnboardingSupabaseClient: Sendable {
    /// Gọi `get_bootstrap()` (1 request) và chọn hồ sơ khởi động.
    /// Nếu tài khoản chưa có hồ sơ nào, trả về `UserProfile` tạm với `isPersisted == false`
    /// và `needsOnboarding == true`.
    public var loadStartupProfile: @Sendable () async throws -> UserProfile
    /// Ghi kết quả onboarding vào schema mới và trả về `profile_id` (chuỗi UUID thường) của hồ sơ.
    /// - `existingProfileId`: hồ sơ đã có trên server (chưa onboarding xong) → `patch_profile`.
    ///   `nil` → insert hồ sơ mới vào `user_profiles` với `draft.pendingProfileId`.
    public var completeOnboarding: @Sendable (
        _ draft: OnboardingDraft,
        _ existingProfileId: String?
    ) async throws -> String
}

extension OnboardingSupabaseClient: DependencyKey {
    private static let profilesTable = "user_profiles"

    public static var liveValue: Self {
        @Dependency(\.supabase) var supabase

        return Self(
            loadStartupProfile: {
                let session = try await supabase.auth.session

                let bootstrap: BootstrapResponseDTO = try await supabase
                    .rpc("get_bootstrap")
                    .execute()
                    .value

                if let row = OnboardingMapper.selectStartupRow(bootstrap) {
                    return OnboardingMapper.toEntity(row)
                }
                return OnboardingMapper.defaultStartupProfile(
                    displayName: fallbackDisplayName(from: session.user)
                )
            },
            completeOnboarding: { draft, existingProfileId in
                let session = try await supabase.auth.session
                let now = Date()

                // 1. Hồ sơ: patch hồ sơ đã có, hoặc insert hồ sơ mới.
                let profileId: UUID
                if let existingId = existingProfileId.flatMap(UUID.init(uuidString:)) {
                    profileId = existingId
                    try await patchProfile(
                        supabase,
                        profileId: profileId,
                        data: OnboardingMapper.toProfileData(draft: draft, includeIdentity: false, now: now)
                    )
                } else {
                    profileId = draft.pendingProfileId ?? UUID()
                    let data = OnboardingMapper.toProfileData(
                        draft: draft,
                        includeIdentity: true,
                        displayName: fallbackDisplayName(from: session.user),
                        now: now
                    )
                    do {
                        try await supabase
                            .from(profilesTable)
                            .insert(
                                UserProfileInsertDTO(
                                    profileId: profileId,
                                    userId: session.user.id,
                                    sortOrder: 0,
                                    data: data
                                )
                            )
                            .execute()
                    } catch let error as PostgrestError where isProfileLimitError(error) {
                        throw OnboardingSupabaseError.profileLimitReached
                    } catch let error as PostgrestError where error.code == "23505" {
                        // Lần thử trước đã insert xong nhưng bước sau lỗi → cập nhật lại hồ sơ đó.
                        try await patchProfile(supabase, profileId: profileId, data: data)
                    }
                }

                // 2. Settings: chọn hồ sơ vừa onboarding làm hồ sơ đang dùng (idempotent).
                try await supabase
                    .rpc(
                        "merge_user_settings",
                        params: MergeUserSettingsParams(
                            patch: UserSettingsDataDTO(activeProfileId: profileId.uuidString.lowercased())
                        )
                    )
                    .execute()

                // 3. Số đo: để cuối cùng vì đây là bước duy nhất không idempotent
                //    (thử lại sau khi bước này thành công sẽ thêm trùng 1 lần đo).
                try await supabase
                    .rpc(
                        "add_body_metric",
                        params: AddBodyMetricParams(
                            profileId: profileId,
                            metric: OnboardingMapper.toBodyMetricDTO(draft: draft, now: now)
                        )
                    )
                    .execute()

                return profileId.uuidString.lowercased()
            }
        )
    }

    public static var previewValue: Self {
        Self(
            loadStartupProfile: {
                OnboardingMapper.defaultStartupProfile()
            },
            completeOnboarding: { draft, existingProfileId in
                existingProfileId ?? (draft.pendingProfileId ?? UUID()).uuidString.lowercased()
            }
        )
    }

    public static var testValue: Self {
        Self()
    }

    private static func patchProfile(
        _ supabase: SupabaseClient,
        profileId: UUID,
        data: ProfileDataDTO
    ) async throws {
        try await supabase
            .rpc("patch_profile", params: PatchProfileParams(profileId: profileId, patch: data))
            .execute()
    }

    /// Trigger giới hạn hồ sơ ném `check_violation` (23514) với thông báo "Mỗi tài khoản tối đa 5 hồ sơ".
    private static func isProfileLimitError(_ error: PostgrestError) -> Bool {
        let message = error.message.lowercased()
        return (error.code == "23514" && message.contains("hồ sơ")) || message.contains("tối đa 5 hồ sơ")
    }

    private static func fallbackDisplayName(from user: User) -> String {
        if let fullName = user.userMetadata["full_name"]?.stringValue,
           !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fullName
        }
        if let name = user.userMetadata["name"]?.stringValue,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        if let email = user.email,
           let prefix = email.split(separator: "@").first,
           !prefix.isEmpty {
            return String(prefix)
        }
        return "Bạn"
    }
}

extension DependencyValues {
    public var onboardingSupabaseClient: OnboardingSupabaseClient {
        get { self[OnboardingSupabaseClient.self] }
        set { self[OnboardingSupabaseClient.self] = newValue }
    }
}
