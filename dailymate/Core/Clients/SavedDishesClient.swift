//
//  SavedDishesClient.swift
//  dailymate
//

import ComposableArchitecture
import Foundation

/// Món đã lưu cục bộ trên máy (không đồng bộ backend).
public struct SavedDish: Codable, Equatable, Identifiable, Sendable {
    public var id: String { dishId }
    public let dishId: String
    public var title: String
    public var imageUrl: String?
    public var nation: String?
    public var cookTimeMin: Int?
    public var estCostVnd: Double?
    public var matchPct: Double?
    public var savedAt: Date

    public var imageURL: URL? {
        imageUrl.flatMap(URL.init(string:))
    }

    public init(
        dishId: String,
        title: String,
        imageUrl: String? = nil,
        nation: String? = nil,
        cookTimeMin: Int? = nil,
        estCostVnd: Double? = nil,
        matchPct: Double? = nil,
        savedAt: Date = Date()
    ) {
        self.dishId = dishId
        self.title = title
        self.imageUrl = imageUrl
        self.nation = nation
        self.cookTimeMin = cookTimeMin
        self.estCostVnd = estCostVnd
        self.matchPct = matchPct
        self.savedAt = savedAt
    }
}

extension SavedDish {
    init(dish: RankedDishDTO, savedAt: Date = Date()) {
        self.init(
            dishId: dish.dishId,
            title: dish.title,
            imageUrl: dish.imageUrl,
            nation: dish.nation,
            cookTimeMin: dish.cookTimeMin,
            estCostVnd: dish.estCostVnd,
            matchPct: Double(dish.resolvedMatchPct),
            savedAt: savedAt
        )
    }

    /// Dựng lại `RankedDishDTO` tối thiểu để mở màn chi tiết (chi tiết đầy đủ sẽ tải lại từ server).
    var rankedDish: RankedDishDTO {
        RankedDishDTO(
            dishId: dishId,
            matchPct: matchPct,
            title: title,
            imageUrl: imageUrl,
            nation: nation,
            cookTimeMin: cookTimeMin,
            estCostVnd: estCostVnd
        )
    }
}

@DependencyClient
public struct SavedDishesClient: Sendable {
    /// Danh sách món đã lưu, mới nhất trước.
    public var load: @Sendable () -> [SavedDish] = { [] }
    public var isSaved: @Sendable (_ dishId: String) -> Bool = { _ in false }
    /// Lưu nếu chưa có, bỏ lưu nếu đã có. Trả về trạng thái mới (`true` = đang lưu).
    public var toggle: @Sendable (_ dish: SavedDish) -> Bool = { _ in false }
    public var remove: @Sendable (_ dishId: String) -> Void = { _ in }
}

extension SavedDishesClient: DependencyKey {
    private static let storageKey = "dailymate.savedDishes.v1"

    public static var liveValue: Self {
        let lock = NSLock()
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        @Sendable func read() -> [SavedDish] {
            guard let data = defaults.data(forKey: storageKey) else { return [] }
            return (try? decoder.decode([SavedDish].self, from: data)) ?? []
        }

        @Sendable func write(_ dishes: [SavedDish]) {
            guard let data = try? encoder.encode(dishes) else { return }
            defaults.set(data, forKey: storageKey)
        }

        return Self(
            load: {
                lock.withLock { read() }
            },
            isSaved: { dishId in
                lock.withLock { read().contains { $0.dishId == dishId } }
            },
            toggle: { dish in
                lock.withLock {
                    var dishes = read()
                    if let index = dishes.firstIndex(where: { $0.dishId == dish.dishId }) {
                        dishes.remove(at: index)
                        write(dishes)
                        return false
                    }
                    dishes.insert(dish, at: 0)
                    write(dishes)
                    return true
                }
            },
            remove: { dishId in
                lock.withLock {
                    var dishes = read()
                    dishes.removeAll { $0.dishId == dishId }
                    write(dishes)
                }
            }
        )
    }

    public static var previewValue: Self {
        let storage = LockIsolated<[SavedDish]>([
            SavedDish(dishId: "10131383", title: "Thịt kho tiêu xanh", nation: "vietnam", cookTimeMin: 30, estCostVnd: 65000, matchPct: 91),
            SavedDish(dishId: "2", title: "Canh chua cá lóc", nation: "vietnam", cookTimeMin: 25, estCostVnd: 50000, matchPct: 84),
        ])
        return Self(
            load: { storage.value },
            isSaved: { id in storage.value.contains { $0.dishId == id } },
            toggle: { dish in
                storage.withValue { dishes in
                    if let index = dishes.firstIndex(where: { $0.dishId == dish.dishId }) {
                        dishes.remove(at: index)
                        return false
                    }
                    dishes.insert(dish, at: 0)
                    return true
                }
            },
            remove: { id in storage.withValue { $0.removeAll { $0.dishId == id } } }
        )
    }

    public static var testValue: Self { Self() }
}

extension DependencyValues {
    public var savedDishesClient: SavedDishesClient {
        get { self[SavedDishesClient.self] }
        set { self[SavedDishesClient.self] = newValue }
    }
}
