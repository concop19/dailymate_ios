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
            return "Tài khoản đã đạt giới hạn tối đa 5 hồ sơ (PROFILE_LIMIT_REACHED)."
        }
    }
}

@DependencyClient
public struct OnboardingSupabaseClient: Sendable {
    /// Đọc hồ sơ khởi động của user từ `public.app_profiles`.
    /// Nếu tài khoản mới chưa có dòng nào, trả về `UserProfile` mặc định với `needsOnboarding == true`.
    public var loadStartupProfile: @Sendable () async throws -> UserProfile
    /// Đọc danh sách dị ứng của `profileId` từ `public.app_allergies`.
    public var loadAllergies: @Sendable (_ profileId: String) async throws -> [AppAllergyRowDTO]
    /// Đồng bộ toàn bộ dữ liệu Onboarding lên 3 bảng Supabase (`app_profiles`, `app_body_metrics`, `app_allergies`).
    public var completeOnboarding: @Sendable (_ draft: OnboardingDraft, _ profileId: String) async throws -> Void
}

extension OnboardingSupabaseClient: DependencyKey {
    private static let profilesTable = "app_profiles"
    private static let bodyMetricsTable = "app_body_metrics"
    private static let allergiesTable = "app_allergies"

    public static var liveValue: Self {
        @Dependency(\.supabase) var supabase

        return Self(
            loadStartupProfile: {
                let session = try await supabase.auth.session
                let userId = session.user.id

                let rows: [AppProfileRowDTO] = try await supabase
                    .from(profilesTable)
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value

                if let selectedRow = rows.first(where: { $0.data.isDefault == true })
                    ?? rows.first(where: { $0.profileId == "self" })
                    ?? rows.first {
                    return OnboardingMapper.toEntity(selectedRow)
                }

                let defaultName = fallbackDisplayName(from: session.user)
                return OnboardingMapper.defaultStartupProfile(
                    profileId: "self",
                    displayName: defaultName
                )
            },
            loadAllergies: { profileId in
                let userId = try await supabase.auth.session.user.id

                let rows: [AppAllergyRowDTO] = try await supabase
                    .from(allergiesTable)
                    .select()
                    .eq("user_id", value: userId)
                    .eq("profile_id", value: profileId)
                    .order("added_at", ascending: true)
                    .execute()
                    .value

                return rows
            },
            completeOnboarding: { draft, profileId in
                let session = try await supabase.auth.session
                let userId = session.user.id
                let now = Date()

                // Lấy dữ liệu profile hiện có (nếu đã tồn tại) để giữ lại displayName / relation / isDefault
                let existingRows: [AppProfileRowDTO] = try await supabase
                    .from(profilesTable)
                    .select()
                    .eq("user_id", value: userId)
                    .eq("profile_id", value: profileId)
                    .limit(1)
                    .execute()
                    .value

                let profileRow = OnboardingMapper.toProfileRowDTO(
                    draft: draft,
                    userId: userId,
                    profileId: profileId,
                    existingData: existingRows.first?.data,
                    defaultDisplayName: fallbackDisplayName(from: session.user),
                    now: now
                )

                // 1. Upsert vào public.app_profiles trước (để thoả mãn FK của app_body_metrics và app_allergies)
                do {
                    try await supabase
                        .from(profilesTable)
                        .upsert(profileRow, onConflict: "user_id,profile_id")
                        .execute()
                } catch let error as PostgrestError where isProfileLimitError(error) {
                    throw OnboardingSupabaseError.profileLimitReached
                }

                // 2. Insert vào public.app_body_metrics (id = nil để Postgres tự sinh gen_random_uuid())
                let bodyMetricsRow = OnboardingMapper.toBodyMetricsRowDTO(
                    draft: draft,
                    userId: userId,
                    profileId: profileId,
                    now: now
                )
                try await supabase
                    .from(bodyMetricsTable)
                    .insert(bodyMetricsRow)
                    .execute()

                // 3. Đồng bộ public.app_allergies: xoá dị ứng cũ của (user_id, profile_id) rồi upsert danh sách mới
                try await supabase
                    .from(allergiesTable)
                    .delete()
                    .eq("user_id", value: userId)
                    .eq("profile_id", value: profileId)
                    .execute()

                let allergyRows = OnboardingMapper.toAllergyRowDTOs(
                    draft: draft,
                    userId: userId,
                    profileId: profileId,
                    now: now
                )
                if !allergyRows.isEmpty {
                    try await supabase
                        .from(allergiesTable)
                        .upsert(allergyRows, onConflict: "user_id,profile_id,allergy_key")
                        .execute()
                }
            }
        )
    }

    public static var previewValue: Self {
        Self(
            loadStartupProfile: {
                OnboardingMapper.defaultStartupProfile()
            },
            loadAllergies: { _ in
                []
            },
            completeOnboarding: { _, _ in }
        )
    }

    public static var testValue: Self {
        Self()
    }

    private static func isProfileLimitError(_ error: PostgrestError) -> Bool {
        error.code == "P0001" || error.message.contains("PROFILE_LIMIT_REACHED")
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
