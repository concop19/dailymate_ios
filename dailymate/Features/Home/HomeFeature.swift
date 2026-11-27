import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @Reducer
    enum Path {
        case ingredientSuggest(IngredientSuggestFeature)
        case dishList(DishListFeature)
        case dishDetail(DishDetailFeature)
        case cookingSteps(CookingStepsFeature)
    }

    @ObservableState
    struct State: Equatable {
        var profile: UserProfile?
        var lat: Double = 16.047
        var lon: Double = 108.206
        var isLoading = false
        var weatherData: WeatherResponseDTO?
        var errorMessage: String?

        // Home UI states
        var isWeatherExpanded: Bool = false
        var selectedCategory: DishCategory = .savory
        var selectedCookingMethods: Set<CookingMethod> = []
        var path = StackState<Path.State>()
        /// Ngăn kéo bên phải "Món đã lưu" — chỉ hiện khi đang ở màn gốc của Home.
        @Presents var savedDishes: SavedDishesFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        /// Đã kiểm tra quyền vị trí trong lần mở app này chưa (chỉ giữ trong bộ nhớ).
        var hasCheckedLocationPermission = false

        var profileName: String {
            let trimmed = profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "Bản thân" : trimmed
        }
    }

    enum Action {
        case onAppear
        case reloadButtonTapped
        case weatherResponse(Result<WeatherResponseDTO, Error>)
        case toggleWeatherExpanded
        case categorySelected(DishCategory)
        case cookingMethodToggled(CookingMethod)
        case profileSwitcherTapped
        case editProfileTapped
        case signOutButtonTapped
        case findButtonTapped
        case path(StackActionOf<Path>)
        case savedDishes(PresentationAction<SavedDishesFeature.Action>)
        case locationPermissionDenied
        case locationResolved(GeoLocation?)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        @CasePathable
        enum Alert: Equatable {
            case openSettingsTapped
            case laterTapped
        }

        @CasePathable
        enum Delegate: Equatable {
            case editProfileRequested
        }
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.homeClient) var homeClient
    @Dependency(\.savedDishesClient) var savedDishesClient
    @Dependency(\.locationPermissionClient) var locationPermissionClient
    @Dependency(\.localClient) var localClient
    @Dependency(\.date.now) var now

    /// Sau khi bị từ chối, chờ 3 ngày mới hỏi lại.
    static let locationAskAgainInterval: TimeInterval = 3 * 24 * 60 * 60

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                presentSavedDishesIfNeeded(&state)
                if !state.hasCheckedLocationPermission {
                    // Lần đầu trong phiên: xin quyền + lấy toạ độ thật, rồi mới tải thời tiết (xem `.locationResolved`).
                    state.hasCheckedLocationPermission = true
                    state.isLoading = true
                    return checkLocationPermission()
                }
                guard state.weatherData == nil, !state.isLoading else { return .none }
                return fetchWeather(&state)

            case let .locationResolved(location):
                // Không có toạ độ (bị từ chối / lỗi / quá giờ) thì giữ toạ độ mặc định.
                if let location {
                    state.lat = location.lat
                    state.lon = location.lon
                }
                return fetchWeather(&state)

            case .locationPermissionDenied:
                state.alert = AlertState {
                    TextState("Cho phép truy cập vị trí")
                } actions: {
                    ButtonState(action: .openSettingsTapped) {
                        TextState("Mở Cài đặt")
                    }
                    ButtonState(role: .cancel, action: .laterTapped) {
                        TextState("Để sau")
                    }
                } message: {
                    TextState("DailyMate cần vị trí để lấy thời tiết nơi bạn ở và gợi ý món phù hợp. Bạn có thể bật lại trong Cài đặt › Vị trí.")
                }
                return .none

            case .alert(.presented(.openSettingsTapped)):
                localClient.saveLocationDeniedAt(now)
                let client = self.locationPermissionClient
                return .run { _ in await client.openSettings() }

            case .alert(.presented(.laterTapped)):
                localClient.saveLocationDeniedAt(now)
                return .none

            case .alert:
                return .none

            case .findButtonTapped:
                // Hiện chỉ có chế độ "Gợi ý tùy chọn"; "Từ tủ lạnh" sẽ nối sau.
                let params = SearchParamsBuilder.base(
                    profile: state.profile,
                    lat: state.lat,
                    lon: state.lon,
                    dishCategory: state.selectedCategory,
                    cookingMethods: state.selectedCookingMethods
                )
                state.path.append(.ingredientSuggest(IngredientSuggestFeature.State(searchParams: params)))
                return .none

            case .reloadButtonTapped:
                return fetchWeather(&state)

            case let .weatherResponse(.success(weather)):
                state.isLoading = false
                state.weatherData = weather
                return .none

            case let .weatherResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .toggleWeatherExpanded:
                state.isWeatherExpanded.toggle()
                return .none

            case let .categorySelected(category):
                state.selectedCategory = category
                return .none

            case let .cookingMethodToggled(method):
                if state.selectedCookingMethods.contains(method) {
                    state.selectedCookingMethods.remove(method)
                } else {
                    state.selectedCookingMethods.insert(method)
                }
                return .none

            case .profileSwitcherTapped:
                return .none

            case .editProfileTapped:
                state.savedDishes = nil
                return .send(.delegate(.editProfileRequested))

            case .delegate:
                return .none

            case .signOutButtonTapped:
                let authClient = self.authClient
                return .run { _ in
                    try? await authClient.signOut()
                }

            case let .path(.element(id: _, action: .ingredientSuggest(.delegate(.completed(params))))):
                state.path.append(.dishList(DishListFeature.State(baseParams: params)))
                return .none

            case let .path(.element(id: elementId, action: .dishList(.delegate(.dishSelected(dish))))):
                var pickedIds: Set<Int> = []
                if case let .dishList(dishListState) = state.path[id: elementId] {
                    pickedIds = Set(dishListState.requestParams.marketBasket?.selectedIngredientIds ?? [])
                }
                state.path.append(
                    .dishDetail(
                        DishDetailFeature.State(
                            dish: dish,
                            pickedIngredientIds: pickedIds
                        )
                    )
                )
                return .none

            case let .path(.element(id: _, action: .dishDetail(.delegate(.cookNow(dish, _))))):
                state.path.append(.cookingSteps(CookingStepsFeature.State(dish: dish)))
                return .none

            case let .savedDishes(.presented(.delegate(.dishSelected(saved)))):
                state.savedDishes = nil
                state.path.append(.dishDetail(DishDetailFeature.State(dish: saved.rankedDish)))
                return .none

            case .savedDishes:
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$savedDishes, action: \.savedDishes) {
            SavedDishesFeature()
        }
        .ifLet(\.$alert, action: \.alert)
        Reduce { state, action in
            // Ngăn kéo chỉ hiện ở màn gốc: ẩn khi push màn mới, hiện lại khi quay về.
            if !state.path.isEmpty {
                state.savedDishes = nil
            } else if case .path = action {
                presentSavedDishesIfNeeded(&state)
            }
            return .none
        }
    }

    /// Kiểm tra quyền vị trí mỗi lần mở app, rồi gửi `.locationResolved` (toạ độ thật nếu được cấp quyền):
    /// - Chưa hỏi lần nào → hiện popup hệ thống. Nếu bị từ chối thì ghi thời điểm vào local.
    /// - Đã cho phép → xoá mốc từ chối.
    /// - Đã từ chối → nếu mốc đã quá 3 ngày (hoặc chưa có mốc) thì hỏi lại bằng alert mời mở Cài đặt,
    ///   vì iOS không cho hiện lại popup hệ thống sau khi bị từ chối.
    private func checkLocationPermission() -> Effect<Action> {
        let permission = self.locationPermissionClient
        let local = self.localClient
        let now = self.now
        return .run { send in
            var status = await permission.authorizationStatus()
            if status == .notDetermined {
                status = await permission.requestWhenInUse()
                if status == .denied {
                    local.saveLocationDeniedAt(now)
                }
            } else if status == .denied {
                let isExpired = local.loadLocationDeniedAt().map {
                    now.timeIntervalSince($0) >= Self.locationAskAgainInterval
                } ?? true
                if isExpired {
                    await send(.locationPermissionDenied)
                }
            }
            // `.restricted`: người dùng không tự đổi được — không làm phiền.

            guard status == .authorized else {
                await send(.locationResolved(nil))
                return
            }
            local.saveLocationDeniedAt(nil)
            await send(.locationResolved(await permission.currentLocation()))
        }
    }

    private func presentSavedDishesIfNeeded(_ state: inout State) {
        guard state.path.isEmpty, state.savedDishes == nil else { return }
        state.savedDishes = SavedDishesFeature.State(dishes: savedDishesClient.load())
    }

    private func fetchWeather(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let lat = state.lat
        let lon = state.lon
        let homeClient = self.homeClient
        return .run { send in
            await send(
                .weatherResponse(
                    Result { try await homeClient.fetchWeatherRawJSON(lat, lon) }
                )
            )
        }
    }
}

extension HomeFeature.Path.State: Equatable {}
