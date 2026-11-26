import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    enum SuggestionMode: String, CaseIterable, Identifiable, Equatable, Sendable {
        case recommended
        case fromFridge
        

        var id: String { rawValue }

        var title: String {
            switch self {
            case .recommended: "Gợi ý tùy chọn."
            case .fromFridge:  "Từ tủ lạnh"
           
            }
        }

        var emoji: String {
            switch self {
            case .recommended: "icon_home_suggest"
            case .fromFridge:  "icon_home_fridge"
           
            }
        }
    }

    enum DishCategory: String, CaseIterable, Identifiable, Equatable, Sendable {
        case all
        case soup
        case savory

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:    "Tất cả"
            case .soup:   "Canh"
            case .savory: "Món mặn"
            }
        }

        var emoji: String {
            switch self {
            case .all:    "🍽️"
            case .soup:   "🥣"
            case .savory: "🍖"
            }
        }

        var apiKey: String {
            switch self {
            case .all:    "all"
            case .soup:   "soup"
            case .savory: "main_dish"
            }
        }
    }

    enum CookingMethod: String, CaseIterable, Identifiable, Equatable, Sendable {
        case riceCooker
        case pan
        case airFryer
        case stirFry
        case braise
        case steam
        case boil

        var id: String { rawValue }

        var title: String {
            switch self {
            case .riceCooker: "Nồi cơm"
            case .pan:        "Chảo"
            case .airFryer:   "chiên "
            case .stirFry:    "Xào"
            case .braise:     "Kho"
            case .steam:      "Hấp"
            case .boil:       "Luộc"
            }
        }

        var emoji: String {
            switch self {
            case .riceCooker: "🍚"
            case .pan:        "🍳"
            case .airFryer:   "🔥"
            case .stirFry:    "🥘"
            case .braise:     "🍲"
            case .steam:      "♨️"
            case .boil:       "🫕"
            }
        }

        var apiKey: String {
            switch self {
            case .riceCooker: "rice_cooker"
            case .pan:        "pan"
            case .airFryer:   "air_fryer"
            case .stirFry:    "stir_fry"
            case .braise:     "braise"
            case .steam:      "steam"
            case .boil:       "boil"
            }
        }
    }

    enum MetricSeverity: Equatable, Sendable {
        case good
        case moderate
        case high
        case veryHigh
    }

    @Reducer
    enum Path {
        case ingredientSuggest(IngredientSuggestFeature)
        case dishList(DishListFeature)
    }

    @ObservableState
    struct State: Equatable {
        var profile: UserProfile?
        var lat: Double = 16.047
        var lon: Double = 108.206
        var isLoading = false
        var WeatherData: WeatherResponseDTO?
        var errorMessage: String?

        // Home UI states
        var isWeatherExpanded: Bool = false
        var selectedMode: SuggestionMode = .recommended
        var selectedCategory: DishCategory = .savory
        var selectedCookingMethods: Set<CookingMethod> = []
        var path = StackState<Path.State>()

        var profileName: String {
            let trimmed = profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? "Bản thân" : trimmed
        }
        // MARK: - Weather Derived

        var skyBackgroundImage: String {
            guard let weatherValue = WeatherData else {
                return "sky_sweety"
            }
            let condition = weatherValue.condition.lowercased()

            if condition.contains("bão") || condition.contains("giông") || condition.contains("dông")
                || condition.contains("sấm") || condition.contains("storm") || condition.contains("thunder") {
                return "sky_stormy"
            }
            if condition.contains("tuyết") || condition.contains("snow") || condition.contains("sleet") {
                return "sky_snowy"
            }
            if condition.contains("mưa") || condition.contains("phùn")
                || condition.contains("rain") || condition.contains("drizzle") || condition.contains("shower") {
                return "sky_rainny"
            }
            if condition.contains("sương") || condition.contains("mù")
                || condition.contains("khói") || condition.contains("bụi")
                || condition.contains("fog") || condition.contains("mist") || condition.contains("haze") {
                return "sky_foggy"
            }
            if condition.contains("mây") || condition.contains("u ám")
                || condition.contains("cloud") || condition.contains("overcast") {
                return "sky_cloudy"
            }
            if condition.contains("nắng") || condition.contains("quang")
                || condition.contains("sun") || condition.contains("clear") {
                return "sky_sunny"
            }
            return "sky_sweety"
        }

        var weatherIcon: String {
            switch skyBackgroundImage {
            case "sky_stormy": return "cloud.bolt.rain.fill"
            case "sky_snowy":  return "snowflake"
            case "sky_rainny": return "cloud.rain.fill"
            case "sky_foggy":  return "cloud.fog.fill"
            case "sky_cloudy": return "cloud.sun.fill"
            case "sky_sunny":  return "sun.max.fill"
            default:           return "cloud.sun.fill"
            }
        }

        var coordinatesText: String {
            String(format: "%.4f, %.4f", lat, lon)
        }

        var temperatureText: String {
            guard let temp = WeatherData?.temperature else { return "--" }
            return "\(Int(temp.rounded()))"
        }

        var feelsLikeText: String {
            guard let weather = WeatherData else { return "Đang cập nhật..." }
            // Xấp xỉ nhiệt độ cảm nhận từ nhiệt độ và độ ẩm khi backend chưa trả feels_like.
            let humidityAdjustment = weather.humidity >= 60 ? 1.0 : 0.0
            let feelsLike = Int((weather.temperature + humidityAdjustment).rounded())
            return "Cảm giác như \(feelsLike)°C"
        }

        var conditionText: String {
            WeatherData?.condition ?? "Đang tải..."
        }

        var seasonTitle: String {
            switch WeatherData?.season.lowercased() {
            case "spring": "Mùa xuân"
            case "summer": "Mùa hạ"
            case "autumn", "fall": "Mùa thu"
            case "winter": "Mùa đông"
            default: "Mùa thu"
            }
        }

        var seasonEmoji: String {
            switch WeatherData?.season.lowercased() {
            case "spring": "🌸"
            case "summer": "☀️"
            case "autumn", "fall": "🍂"
            case "winter": "❄️"
            default: "🍂"
            }
        }

        var humidityText: String {
            guard let humidity = WeatherData?.humidity else { return "--" }
            return "\(Int(humidity.rounded()))"
        }

        var windSpeedText: String {
            guard let wind = WeatherData?.windSpeed else { return "--" }
            return String(format: "%.1f", wind).replacingOccurrences(of: ".", with: ",")
        }

        var pressureText: String {
            guard let pressure = WeatherData?.pressure else { return "--" }
            return "\(Int(pressure.rounded()))"
        }

        var aqiValue: Int {
            WeatherData?.aqi ?? 0
        }

        var aqiLabel: String {
            switch aqiValue {
            case ...50:    "Tốt"
            case 51...100: "Trung bình"
            case 101...150: "Kém"
            default:       "Xấu"
            }
        }

        var aqiSeverity: MetricSeverity {
            switch aqiValue {
            case ...50:    .good
            case 51...100: .moderate
            case 101...150: .high
            default:       .veryHigh
            }
        }

        var aqiProgress: Double {
            min(max(Double(aqiValue) / 300.0, 0), 1)
        }

        var uvValue: Double {
            WeatherData?.uvIndex ?? 0
        }

        var uvFormattedText: String {
            String(format: "%.1f", uvValue).replacingOccurrences(of: ".", with: ",")
        }

        var uvLevelText: String {
            switch uvValue {
            case ..<3: "Thấp"
            case 3..<6: "Trung bình"
            case 6..<8: "Cao"
            default:   "Rất cao"
            }
        }

        var uvSeverity: MetricSeverity {
            switch uvValue {
            case ..<3: .good
            case 3..<6: .moderate
            case 6..<8: .high
            default:   .veryHigh
            }
        }

        var uvProgress: Double {
            min(max(uvValue / 11.0, 0), 1)
        }
    }

    enum Action {
        case onAppear
        case reloadButtonTapped
        case weatherResponse(Result<WeatherResponseDTO, Error>)
        case toggleWeatherExpanded
        case modeSelected(SuggestionMode)
        case categorySelected(DishCategory)
        case cookingMethodToggled(CookingMethod)
        case profileSwitcherTapped
        case signOutButtonTapped
        case findingButtonTapp
        case path(StackActionOf<Path>)
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.homeClient) var homeClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.WeatherData == nil, !state.isLoading else { return .none }
                return fetchWeather(&state)

            case .findingButtonTapp:
                switch state.selectedMode {
                case .recommended:
                    let params = SearchParamsBuilder.base(
                        profile: state.profile,
                        lat: state.lat,
                        lon: state.lon,
                        dishCategory: state.selectedCategory,
                        cookingMethods: state.selectedCookingMethods
                    )
                    state.path.append(.ingredientSuggest(IngredientSuggestFeature.State(searchParams: params)))
                    return .none
                case .fromFridge:
                    // Case 2 (Từ tủ lạnh) sẽ nối sau.
                    return .none
                }

            case .reloadButtonTapped:
                return fetchWeather(&state)

            case let .weatherResponse(.success(weather)):
                state.isLoading = false
                state.WeatherData = weather
                return .none

            case let .weatherResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .toggleWeatherExpanded:
                state.isWeatherExpanded.toggle()
                return .none

            case let .modeSelected(mode):
                state.selectedMode = mode
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

            case .signOutButtonTapped:
                let authClient = self.authClient
                return .run { _ in
                    try? await authClient.signOut()
                }

            case let .path(.element(id: _, action: .ingredientSuggest(.delegate(.completed(params))))):
                state.path.append(.dishList(DishListFeature.State(baseParams: params)))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
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
