import Foundation

// Encodable lets JSONEncoder turn this into the JSON body the API expects.
struct TripInput: Encodable {
    var startDate: Date = Date()
    var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    var originAirport: String = "SNA"
    var skillLevel: String = "intermediate"
    var budgetLevel: String = "mid"

    // Map Swift camelCase → snake_case for the API
    enum CodingKeys: String, CodingKey {
        case startDate    = "start_date"
        case endDate      = "end_date"
        case originAirport = "origin_airport"
        case skillLevel   = "skill_level"
        case budgetLevel  = "budget_level"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        try c.encode(fmt.string(from: startDate), forKey: .startDate)
        try c.encode(fmt.string(from: endDate), forKey: .endDate)
        try c.encode(originAirport, forKey: .originAirport)
        try c.encode(skillLevel, forKey: .skillLevel)
        try c.encode(budgetLevel, forKey: .budgetLevel)
    }
}
