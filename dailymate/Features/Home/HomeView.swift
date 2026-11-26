import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    private var shortVietnameseDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM"
        let raw = formatter.string(from: Date())
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
            VStack(spacing: 18) {
                HomeHeaderView(
                    coordinatesText: store.coordinatesText,
                    dateText: shortVietnameseDate,
                   
                )
                HomeWeatherHeroView(
                    weatherIcon: store.weatherIcon,
                    temperatureText: store.temperatureText,
                    conditionText: store.conditionText,
                    feelsLikeText: store.feelsLikeText,
                    seasonTitle: store.seasonTitle,
                    seasonEmoji: store.seasonEmoji,
                    isLoading: store.isLoading
                )
                .padding(.top, 4)

                if let error = store.errorMessage {
                    HStack(spacing: 10) {
                        OnboardingErrorText(error)
                        Spacer()
                        Button("Thử lại") {
                            store.send(.reloadButtonTapped)
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.Ghibli.wood)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xFAF5EA).opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                HomeWeatherDetailsView(
                    isExpanded: store.isWeatherExpanded,
                    humidityText: store.humidityText,
                    windSpeedText: store.windSpeedText,
                    pressureText: store.pressureText,
                    aqiValue: store.aqiValue,
                    aqiLabel: store.aqiLabel,
                    aqiSeverity: store.aqiSeverity,
                    aqiProgress: store.aqiProgress,
                    uvFormattedText: store.uvFormattedText,
                    uvLevelText: store.uvLevelText,
                    uvSeverity: store.uvSeverity,
                    uvProgress: store.uvProgress
                ) {
                    store.send(.toggleWeatherExpanded)
                }

                HomeModeCardsView(selectedMode: store.selectedMode) { mode in
                    store.send(.modeSelected(mode))
                }

                HomeSearchOptionsView(
                    selectedCategory: store.selectedCategory,
                    selectedCookingMethods: store.selectedCookingMethods,
                    onSelectCategory: { category in
                        store.send(.categorySelected(category))
                    },
                    onToggleCookingMethod: { method in
                        store.send(.cookingMethodToggled(method))
                    }
                )
                Button {
                    store.send(.findingButtonTapp)
                } label: {
                    Text("\(store.selectedCategory.emoji)  Finding")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Ghibli.sky, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.Ghibli.skyDeep.opacity(0.35), lineWidth: 1)
                        }
                        .shadow(color: Color.Ghibli.skyDeep.opacity(0.28), radius: 8, y: 4)
                }
                .buttonStyle(.ghibliPress)
                
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.Ghibli.cream
                .overlay {
                    Image(store.skyBackgroundImage)
                        .resizable()
                        .scaledToFill()
                }
                .overlay { Color.Ghibli.creamOverlay.opacity(0.55) }
                .clipped()
                .ignoresSafeArea()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: store.isWeatherExpanded)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
        } destination: { store in
            switch store.case {
            case let .ingredientSuggest(suggestStore):
                IngredientSuggestView(store: suggestStore)
            case let .dishList(dishListStore):
                DishListView(store: dishListStore)
            }
        }
    }
}

#Preview("Home — Thu gọn") {
    HomeView(
        store: Store(
            initialState: HomeFeature.State(
                lat: 16.0600,
                lon: 108.2100,
                WeatherData: WeatherResponseDTO(
                    aqi: 60,
                    cacheHit: false,
                    condition: "Có mây",
                    expiresAt: nil,
                    humidity: 66,
                    pressure: 1015,
                    season: "autumn",
                    temperature: 30,
                    uvIndex: 0,
                    weatherSource: "openweather",
                    weatherVector: WeatherVectorDTO(
                        coldStressIndex: 0,
                        comfortable: 0,
                        dehydrationRisk: 0.21,
                        heatStressIndex: 0.30,
                        immuneLoad: 0.30,
                        infectionRisk: 0.11,
                        oxidativeStressRisk: 0.11
                    ),
                    windSpeed: 1.8
                ),
                isWeatherExpanded: false,
                selectedMode: .recommended,
                selectedCategory: .savory
            )
        ) {
            HomeFeature()
        }
    )
}

#Preview("Home — Mở rộng thời tiết") {
    HomeView(
        store: Store(
            initialState: HomeFeature.State(
                lat: 16.0600,
                lon: 108.2100,
                WeatherData: WeatherResponseDTO(
                    aqi: 60,
                    cacheHit: false,
                    condition: "Có mây",
                    expiresAt: nil,
                    humidity: 66,
                    pressure: 1015,
                    season: "autumn",
                    temperature: 30,
                    uvIndex: 0,
                    weatherSource: "openweather",
                    weatherVector: WeatherVectorDTO(
                        coldStressIndex: 0,
                        comfortable: 0,
                        dehydrationRisk: 0.21,
                        heatStressIndex: 0.30,
                        immuneLoad: 0.30,
                        infectionRisk: 0.11,
                        oxidativeStressRisk: 0.11
                    ),
                    windSpeed: 1.8
                ),
                isWeatherExpanded: true
            )
        ) {
            HomeFeature()
        }
    )
}
