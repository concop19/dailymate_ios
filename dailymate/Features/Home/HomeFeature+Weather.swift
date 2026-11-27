//
//  HomeFeature+Weather.swift
//  dailymate
//

import Foundation

// MARK: - Weather Derived

extension HomeFeature.State {

    var skyBackgroundImage: String {
        guard let weatherValue = weatherData else {
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
        guard let temp = weatherData?.temperature else { return "--" }
        return "\(Int(temp.rounded()))"
    }

    var feelsLikeText: String {
        guard let weather = weatherData else { return "Đang cập nhật..." }
        // Xấp xỉ nhiệt độ cảm nhận từ nhiệt độ và độ ẩm khi backend chưa trả feels_like.
        let humidityAdjustment = weather.humidity >= 60 ? 1.0 : 0.0
        let feelsLike = Int((weather.temperature + humidityAdjustment).rounded())
        return "Cảm giác như \(feelsLike)°C"
    }

    var conditionText: String {
        weatherData?.condition ?? "Đang tải..."
    }

    var seasonTitle: String {
        switch weatherData?.season.lowercased() {
        case "spring": "Mùa xuân"
        case "summer": "Mùa hạ"
        case "autumn", "fall": "Mùa thu"
        case "winter": "Mùa đông"
        default: "Mùa thu"
        }
    }

    var seasonEmoji: String {
        switch weatherData?.season.lowercased() {
        case "spring": "🌸"
        case "summer": "☀️"
        case "autumn", "fall": "🍂"
        case "winter": "❄️"
        default: "🍂"
        }
    }

    var humidityText: String {
        guard let humidity = weatherData?.humidity else { return "--" }
        return "\(Int(humidity.rounded()))"
    }

    var windSpeedText: String {
        guard let wind = weatherData?.windSpeed else { return "--" }
        return String(format: "%.1f", wind).replacingOccurrences(of: ".", with: ",")
    }

    var pressureText: String {
        guard let pressure = weatherData?.pressure else { return "--" }
        return "\(Int(pressure.rounded()))"
    }

    var aqiValue: Int {
        weatherData?.aqi ?? 0
    }

    var aqiLabel: String {
        switch aqiValue {
        case ...50:    "Tốt"
        case 51...100: "Trung bình"
        case 101...150: "Kém"
        default:       "Xấu"
        }
    }

    var aqiSeverity: HomeFeature.MetricSeverity {
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
        weatherData?.uvIndex ?? 0
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

    var uvSeverity: HomeFeature.MetricSeverity {
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
