//
//  LocationPermissionClient.swift
//  dailymate
//

import ComposableArchitecture
import CoreLocation
import UIKit

/// Trạng thái quyền truy cập vị trí, rút gọn từ `CLAuthorizationStatus`.
enum LocationAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    /// Bị giới hạn bởi hệ thống (Screen Time, MDM...) — người dùng không tự đổi được.
    case restricted

    init(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: self = .authorized
        case .restricted: self = .restricted
        case .denied: self = .denied
        @unknown default: self = .denied
        }
    }
}

@DependencyClient
struct LocationPermissionClient: Sendable {
    /// Trạng thái quyền hiện tại (không hỏi người dùng).
    var authorizationStatus: @Sendable () async -> LocationAuthorization = { .notDetermined }
    /// Hiện popup hệ thống xin quyền "Khi dùng app" nếu chưa hỏi lần nào; trả về trạng thái sau khi người dùng chọn.
    /// iOS chỉ cho hiện popup này một lần — các lần sau trả về ngay trạng thái hiện tại.
    var requestWhenInUse: @Sendable () async -> LocationAuthorization = { .notDetermined }
    /// Mở trang Cài đặt của app để người dùng tự bật lại quyền vị trí.
    var openSettings: @Sendable () async -> Void
    /// Lấy toạ độ hiện tại một lần (độ chính xác ~1km, tối đa 10 giây). `nil` nếu chưa có quyền, lỗi hoặc quá thời gian.
    var currentLocation: @Sendable () async -> GeoLocation? = { nil }
}

extension LocationPermissionClient: DependencyKey {
    static var liveValue: Self {
        Self(
            authorizationStatus: {
                await LocationPermissionManager.shared.status
            },
            requestWhenInUse: {
                await LocationPermissionManager.shared.requestWhenInUse()
            },
            openSettings: {
                await LocationPermissionManager.openSettings()
            },
            currentLocation: {
                await LocationPermissionManager.shared.currentLocation()
            }
        )
    }

    static var previewValue: Self {
        Self(
            authorizationStatus: { .authorized },
            requestWhenInUse: { .authorized },
            openSettings: {},
            currentLocation: { GeoLocation(lat: 16.047, lon: 108.206) }
        )
    }

    static var testValue: Self { Self() }
}

extension DependencyValues {
    var locationPermissionClient: LocationPermissionClient {
        get { self[LocationPermissionClient.self] }
        set { self[LocationPermissionClient.self] = newValue }
    }
}

// MARK: - CLLocationManager wrapper

@MainActor
private final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()

    private let manager = CLLocationManager()
    private var pending: [CheckedContinuation<LocationAuthorization, Never>] = []
    private var pendingLocation: [CheckedContinuation<GeoLocation?, Never>] = []
    private var locationRequestID = 0
    private static let locationTimeout: Duration = .seconds(10)

    override init() {
        super.init()
        manager.delegate = self
        // Thời tiết theo khu vực — không cần GPS chính xác, lấy nhanh và đỡ pin hơn.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentLocation() async -> GeoLocation? {
        guard status == .authorized else { return nil }
        return await withCheckedContinuation { continuation in
            pendingLocation.append(continuation)
            guard pendingLocation.count == 1 else { return }
            locationRequestID += 1
            let requestID = locationRequestID
            manager.requestLocation()
            Task { @MainActor in
                try? await Task.sleep(for: Self.locationTimeout)
                // Chỉ huỷ đúng lần yêu cầu này, không đụng tới lần gọi sau.
                guard self.locationRequestID == requestID else { return }
                self.resumeLocation(nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last.map {
            GeoLocation(lat: $0.coordinate.latitude, lon: $0.coordinate.longitude)
        }
        Task { @MainActor in self.resumeLocation(location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        Task { @MainActor in self.resumeLocation(nil) }
    }

    private func resumeLocation(_ location: GeoLocation?) {
        guard !pendingLocation.isEmpty else { return }
        locationRequestID += 1
        let continuations = pendingLocation
        pendingLocation.removeAll()
        continuations.forEach { $0.resume(returning: location) }
    }

    var status: LocationAuthorization {
        LocationAuthorization(manager.authorizationStatus)
    }

    func requestWhenInUse() async -> LocationAuthorization {
        guard manager.authorizationStatus == .notDetermined else { return status }
        return await withCheckedContinuation { continuation in
            pending.append(continuation)
            manager.requestWhenInUseAuthorization()
        }
    }

    static func openSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        _ = await UIApplication.shared.open(url)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.resumePending() }
    }

    private func resumePending() {
        let current = status
        // Delegate cũng được gọi ngay khi gán (lúc còn notDetermined) — bỏ qua cho tới khi người dùng chọn.
        guard current != .notDetermined, !pending.isEmpty else { return }
        let continuations = pending
        pending.removeAll()
        continuations.forEach { $0.resume(returning: current) }
    }
}
