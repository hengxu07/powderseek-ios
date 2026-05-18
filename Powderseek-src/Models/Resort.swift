import Foundation

// Decodable lets JSONDecoder parse the /resorts API response automatically.
struct ResortSummary: Decodable, Identifiable {
    let id: Int
    let name: String
    let slug: String
}

struct ForecastDay: Decodable, Identifiable {
    let id = UUID()
    let forecastDate: String
    let newSnowCm: Double?
    let cumulative7dCm: Double?
    let baseDepthCm: Int?
    let temperatureC: Double?
    let windKph: Double?

    enum CodingKeys: String, CodingKey {
        case forecastDate  = "forecast_date"
        case newSnowCm     = "new_snow_cm"
        case cumulative7dCm = "cumulative_7d_cm"
        case baseDepthCm   = "base_depth_cm"
        case temperatureC  = "temperature_c"
        case windKph       = "wind_kph"
    }
}

struct ResortDetail: Decodable {
    let id: Int
    let name: String
    let slug: String
    let country: String
    let continent: String
    let elevationBaseM: Int
    let elevationSummitM: Int
    let verticalDropM: Int
    let nearestAirport: String
    let airportDriveMinutes: Int
    let seasonStartMonth: Int
    let seasonEndMonth: Int
    let avgAnnualSnowfallCm: Int?
    let difficultyMix: [String: Int]?
    let terrainTags: [String]
    let vibeTags: [String]
    let budgetTier: String?
    let snowboardAllowed: Bool
    let forecastDays: [ForecastDay]

    enum CodingKeys: String, CodingKey {
        case id, name, slug, country, continent
        case elevationBaseM    = "elevation_base_m"
        case elevationSummitM  = "elevation_summit_m"
        case verticalDropM     = "vertical_drop_m"
        case nearestAirport    = "nearest_airport"
        case airportDriveMinutes = "airport_drive_minutes"
        case seasonStartMonth  = "season_start_month"
        case seasonEndMonth    = "season_end_month"
        case avgAnnualSnowfallCm = "avg_annual_snowfall_cm"
        case difficultyMix     = "difficulty_mix"
        case terrainTags       = "terrain_tags"
        case vibeTags          = "vibe_tags"
        case budgetTier        = "budget_tier"
        case snowboardAllowed  = "snowboard_allowed"
        case forecastDays      = "forecast_days"
    }
}
