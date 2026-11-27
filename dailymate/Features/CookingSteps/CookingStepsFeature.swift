//
//  CookingStepsFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CookingStepsFeature {
    enum StepsError: Equatable, Sendable {
        case empty
        case notFound
        case authExpired
        case network

        var title: String {
            switch self {
            case .empty:       "Món này chưa có hướng dẫn nấu"
            case .notFound:    "Không tìm thấy công thức"
            case .authExpired: "Phiên đăng nhập đã hết hạn"
            case .network:     "Không tải được các bước nấu"
            }
        }

        var message: String {
            switch self {
            case .empty:       "Bạn có thể xem công thức gốc để nấu theo nhé."
            case .notFound:    "Công thức của món này có thể đã bị gỡ."
            case .authExpired: "Vui lòng đăng nhập lại để tiếp tục."
            case .network:     "Kiểm tra kết nối mạng rồi thử lại nha."
            }
        }

        var canRetry: Bool { self == .network }
    }

    @ObservableState
    struct State: Equatable {
        let dishId: String
        var title: String
        var sourceURL: URL?
        var isLoading = false
        var error: StepsError?
        var steps: [CookingStepDTO] = []
        var cookTimeMinutes: Int?
        var methodId: String?
        /// Nội dung không theo ngôn ngữ app (server chỉ có tiếng Việt).
        var languageMismatch = false
        var done: Set<Int> = []
        /// Mặc định mở chế độ từng bước (nền bếp + Lottie), danh sách là chế độ phụ.
        var isFocusMode = true
        var focusIndex = 0
        var showIllustrationNote = true
        var showFinishPopup = false

        init(dishId: String, title: String = "", sourceURL: URL? = nil) {
            self.dishId = dishId
            self.title = title
            self.sourceURL = sourceURL
        }

        init(dish: RankedDishDTO) {
            let url = dish.url.flatMap { $0.isEmpty ? nil : URL(string: $0) }
            self.init(dishId: dish.dishId, title: dish.title, sourceURL: url)
        }

        var currentStep: CookingStepDTO? { steps.indices.contains(focusIndex) ? steps[focusIndex] : nil }
        var isFirstStep: Bool { focusIndex <= 0 }
        var isLastStep: Bool { focusIndex >= steps.count - 1 }
        var allDone: Bool { !steps.isEmpty && done.count >= steps.count }
        var progress: Double { steps.isEmpty ? 0 : Double(done.count) / Double(steps.count) }
        var currentAction: CookingAction { CookingAction.resolve(currentStep?.actionType) }
        var methodLabel: String? { CookingMethodLabel.label(for: methodId) }
        var showsFocusScreen: Bool { isFocusMode && !isLoading && error == nil && !steps.isEmpty }
    }

    enum Action {
        case onAppear
        case retryTapped
        case stepsResponse(Result<CookingStepsDTO, Error>)
        case toggleStep(Int)
        case setFocusMode(Bool)
        case stepSelected(Int)
        /// Chế độ từng bước: đánh dấu bước hiện tại xong rồi sang bước sau (bước cuối → popup hoàn thành).
        case nextTapped
        case prevTapped
        case resetTapped
        case hideIllustrationNote
        case finishPopupDismissed
        case finishConfirmed
        case backTapped
    }

    private enum CancelID: Hashable {
        case fetch
        case illustrationNote
    }

    @Dependency(\.dishDetailClient) var dishDetailClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.steps.isEmpty, !state.isLoading else { return .none }
                let clock = self.clock
                return .merge(
                    fetch(&state),
                    .run { send in
                        try await clock.sleep(for: .seconds(4.5))
                        await send(.hideIllustrationNote)
                    }
                    .cancellable(id: CancelID.illustrationNote, cancelInFlight: true)
                )

            case .retryTapped:
                return fetch(&state)

            case let .stepsResponse(.success(data)):
                state.isLoading = false
                state.steps = data.steps
                state.error = data.steps.isEmpty ? .empty : nil
                if state.title.isEmpty { state.title = data.title ?? "" }
                state.cookTimeMinutes = data.cookTimeMinutes
                state.methodId = data.cookingMethodId
                state.languageMismatch = data.language.map { $0 != "vi" } ?? false
                state.focusIndex = 0
                return .none

            case let .stepsResponse(.failure(error)):
                state.isLoading = false
                state.error = Self.mapError(error)
                return .none

            case let .toggleStep(stepNo):
                if state.done.contains(stepNo) {
                    state.done.remove(stepNo)
                } else {
                    state.done.insert(stepNo)
                }
                return .none

            case let .setFocusMode(isFocus):
                state.isFocusMode = isFocus
                // Mở chế độ từng bước ở bước đầu tiên chưa xong.
                state.focusIndex = state.steps.firstIndex { !state.done.contains($0.stepNo) } ?? 0
                return .none

            case let .stepSelected(index):
                guard state.steps.indices.contains(index) else { return .none }
                state.focusIndex = index
                return .none

            case .nextTapped:
                guard let current = state.currentStep else { return .none }
                state.done.insert(current.stepNo)
                if state.isLastStep {
                    state.showFinishPopup = true
                } else {
                    state.focusIndex += 1
                }
                return .none

            case .prevTapped:
                state.focusIndex = max(0, state.focusIndex - 1)
                return .none

            case .resetTapped:
                state.done = []
                state.focusIndex = 0
                return .none

            case .hideIllustrationNote:
                state.showIllustrationNote = false
                return .cancel(id: CancelID.illustrationNote)

            case .finishPopupDismissed:
                state.showFinishPopup = false
                return .none

            case .finishConfirmed, .backTapped:
                state.showFinishPopup = false
                let dismiss = self.dismiss
                return .run { _ in await dismiss() }
            }
        }
    }

    private func fetch(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.error = nil
        let dishId = state.dishId
        let client = self.dishDetailClient
        return .run { send in
            await send(.stepsResponse(Result { try await client.getCookingSteps(dishId) }))
        }
        .cancellable(id: CancelID.fetch, cancelInFlight: true)
    }

    private static func mapError(_ error: Error) -> StepsError {
        guard let backendError = error as? BackendError else { return .network }
        switch backendError {
        case .unauthorized:
            return .authExpired
        case let .api(apiError) where apiError.statusCode == 401:
            return .authExpired
        case let .api(apiError) where apiError.statusCode == 404:
            return .notFound
        default:
            return .network
        }
    }
}
