//
//  LocalClient.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct LocalClient: Sendable {
    /// Lấy bản nháp onboarding từ bộ nhớ cục bộ theo `(userId, profileId)`.
    public var loadDraft: @Sendable (_ userId: UUID, _ profileId: String) -> OnboardingDraft?
    /// Lưu bản nháp onboarding vào bộ nhớ cục bộ theo `(userId, profileId)`.
    public var saveDraft: @Sendable (_ draft: OnboardingDraft, _ userId: UUID, _ profileId: String) -> Void
    /// Xoá bản nháp onboarding sau khi hoàn tất hoặc huỷ.
    public var clearDraft: @Sendable (_ userId: UUID, _ profileId: String) -> Void
    /// Hồ sơ khởi động đã cache của `userId` (hiển thị ngay khi mở app, kể cả lúc mất mạng).
    public var loadStartupProfile: @Sendable (_ userId: UUID) -> UserProfile?
    /// Cache hồ sơ khởi động của `userId` sau khi tải từ server hoặc hoàn tất onboarding.
    public var saveStartupProfile: @Sendable (_ profile: UserProfile, _ userId: UUID) -> Void
    /// Danh sách tối đa 3 `dish_id` gần nhất để gửi vào `recent_dish_ids` của `/api/v1/recommend`.
    public var loadRecentDishIds: @Sendable () -> [String] = { [] }
    /// Lưu danh sách `recent_dish_ids` (tự cắt tối đa 3 phần tử mới nhất).
    public var saveRecentDishIds: @Sendable (_ dishIds: [String]) -> Void = { _ in }
    /// Thời điểm người dùng từ chối (hoặc bấm "Để sau") quyền vị trí gần nhất. `nil` = chưa có / đã cho phép.
    public var loadLocationDeniedAt: @Sendable () -> Date? = { nil }
    /// Ghi / xoá (`nil`) thời điểm từ chối quyền vị trí.
    public var saveLocationDeniedAt: @Sendable (_ date: Date?) -> Void = { _ in }
}

extension LocalClient: DependencyKey {
    private static let keyPrefix = "dailymate.onboarding.draft"
    private static let startupProfileKeyPrefix = "dailymate.startup.profile"
    private static let recentDishIdsKey = "dailymate.recommend.recentDishIds"
    private static let locationDeniedAtKey = "dailymate.location.deniedAt"

    private static func startupProfileKey(userId: UUID) -> String {
        "\(startupProfileKeyPrefix).\(userId.uuidString.lowercased())"
    }

    private static func storageKey(userId: UUID, profileId: String) -> String {
        "\(keyPrefix).\(userId.uuidString.lowercased()).\(profileId)"
    }

    public static var liveValue: Self {
        makeLive()
    }

    public static func makeLive(
        suiteName: String? = nil
    ) -> Self {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        return Self(
            loadDraft: { userId, profileId in
                let defaults: UserDefaults
                if let name = suiteName, let customDefaults = UserDefaults(suiteName: name) {
                    defaults = customDefaults
                } else {
                    defaults = UserDefaults.standard }
                let key = storageKey(userId: userId, profileId: profileId)
                guard let data = defaults.data(forKey: key) else { return nil }
                return try? decoder.decode(OnboardingDraft.self, from: data)
            },
            saveDraft: { draft, userId, profileId in
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                let key = storageKey(userId: userId, profileId: profileId)
                guard let data = try? encoder.encode(draft) else { return }
                defaults.set(data, forKey: key)
            },
            clearDraft: { userId, profileId in
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                let key = storageKey(userId: userId, profileId: profileId)
                defaults.removeObject(forKey: key)
            },
            loadStartupProfile: { userId in
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                guard let data = defaults.data(forKey: startupProfileKey(userId: userId)) else { return nil }
                return try? decoder.decode(UserProfile.self, from: data)
            },
            saveStartupProfile: { profile, userId in
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                guard let data = try? encoder.encode(profile) else { return }
                defaults.set(data, forKey: startupProfileKey(userId: userId))
            },
            loadRecentDishIds: {
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                return defaults.stringArray(forKey: recentDishIdsKey) ?? []
            },
            saveRecentDishIds: { dishIds in
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                let trimmed = Array(dishIds.prefix(3))
                defaults.set(trimmed, forKey: recentDishIdsKey)
            },
            loadLocationDeniedAt: {
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                return defaults.object(forKey: locationDeniedAtKey) as? Date
            },
            saveLocationDeniedAt: { date in
                let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
                if let date {
                    defaults.set(date, forKey: locationDeniedAtKey)
                } else {
                    defaults.removeObject(forKey: locationDeniedAtKey)
                }
            }
        )
    }

    public static var previewValue: Self {
        let storage = LockIsolated<[String: OnboardingDraft]>([:])
        let profiles = LockIsolated<[UUID: UserProfile]>([:])
        let recentDishes = LockIsolated<[String]>([])
        let locationDeniedAt = LockIsolated<Date?>(nil)
        return Self(
            loadDraft: { userId, profileId in
                storage.value[storageKey(userId: userId, profileId: profileId)]
            },
            saveDraft: { draft, userId, profileId in
                storage.withValue {
                    $0[storageKey(userId: userId, profileId: profileId)] = draft
                }
            },
            clearDraft: { userId, profileId in
                storage.withValue {
                    $0.removeValue(forKey: storageKey(userId: userId, profileId: profileId))
                }
            },
            loadStartupProfile: { userId in
                profiles.value[userId]
            },
            saveStartupProfile: { profile, userId in
                profiles.withValue { $0[userId] = profile }
            },
            loadRecentDishIds: {
                recentDishes.value
            },
            saveRecentDishIds: { dishIds in
                recentDishes.setValue(Array(dishIds.prefix(3)))
            },
            loadLocationDeniedAt: {
                locationDeniedAt.value
            },
            saveLocationDeniedAt: { date in
                locationDeniedAt.setValue(date)
            }
        )
    }

    public static var testValue: Self {
        Self()
    }
}

extension DependencyValues {
    public var localClient: LocalClient {
        get { self[LocalClient.self] }
        set { self[LocalClient.self] = newValue }
    }
}
