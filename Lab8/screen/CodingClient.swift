import Foundation

nonisolated enum CodingError: LocalizedError, Equatable {
    case userNotFound
    case badStatus(Int)
    case noActivity

    var errorDescription: String? {
        switch self {
        case .userNotFound: "User not found"
        case .badStatus(let code): "Server answered with status \(code)"
        case .noActivity: "No activity data"
        }
    }
}

nonisolated struct CodingFetch: Sendable {
    var leetcode: Result<LeetCodeCounts, Error>?
    var codewars: Result<Int, Error>?
    var stepik: Result<Int, Error>?

    var errors: [CodingPlatform: String] {
        var errors: [CodingPlatform: String] = [:]
        if case .failure(let error) = leetcode { errors[.leetcode] = error.localizedDescription }
        if case .failure(let error) = codewars { errors[.codewars] = error.localizedDescription }
        if case .failure(let error) = stepik { errors[.stepik] = error.localizedDescription }
        return errors
    }
}

nonisolated struct CodingClient: Sendable {
    var session = URLSession.shared

    func fetch(_ config: CodingConfig) async -> CodingFetch {
        async let leetcode = attempt(config.account(.leetcode), leetCode)
        async let codewars = attempt(config.account(.codewars), codewarsHonor)
        async let stepik = attempt(config.account(.stepik), stepikToday)
        return await CodingFetch(leetcode: leetcode, codewars: codewars, stepik: stepik)
    }

    func leetCode(_ user: String) async throws -> LeetCodeCounts {
        var request = URLRequest(url: URL(string: "https://leetcode.com/graphql/")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.httpBody = try JSONEncoder().encode(LeetCodeQuery(username: user))
        return try Self.parseLeetCode(try await load(request))
    }

    func codewarsHonor(_ user: String) async throws -> Int {
        let path = user.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? user
        let request = URLRequest(url: URL(string: "https://www.codewars.com/api/v1/users/\(path)")!)
        return try Self.parseCodewars(try await load(request))
    }

    func stepikToday(_ id: String) async throws -> Int {
        guard let number = Int(id) else { throw CodingError.userNotFound }
        let request = URLRequest(url: URL(string: "https://stepik.org/api/user-activities/\(number)")!)
        return try Self.parseStepik(try await load(request))
    }

    static func parseLeetCode(_ data: Data) throws -> LeetCodeCounts {
        let response = try JSONDecoder().decode(LeetCodeResponse.self, from: data)
        guard let entries = response.data.matchedUser?.submitStatsGlobal.acSubmissionNum else { throw CodingError.userNotFound }
        let count = { (difficulty: String) in entries.first { $0.difficulty == difficulty }?.count ?? 0 }
        return LeetCodeCounts(easy: count("Easy"), medium: count("Medium"), hard: count("Hard"))
    }

    static func parseCodewars(_ data: Data) throws -> Int {
        try JSONDecoder().decode(CodewarsUser.self, from: data).honor
    }

    static func parseStepik(_ data: Data) throws -> Int {
        let response = try JSONDecoder().decode(StepikActivities.self, from: data)
        guard let today = response.activities.first?.pins.first else { throw CodingError.noActivity }
        return today
    }

    private func attempt<T>(_ account: String, _ load: (String) async throws -> T) async -> Result<T, Error>? {
        guard !account.isEmpty else { return nil }
        do {
            return .success(try await load(account))
        } catch {
            return .failure(error)
        }
    }

    private func load(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status != 404 else { throw CodingError.userNotFound }
        guard (200..<300).contains(status) else { throw CodingError.badStatus(status) }
        return data
    }
}

private nonisolated struct LeetCodeQuery: Encodable {
    let query = "query($username: String!) { matchedUser(username: $username) { submitStatsGlobal { acSubmissionNum { difficulty count } } } }"
    let variables: [String: String]

    init(username: String) {
        variables = ["username": username]
    }
}

private nonisolated struct LeetCodeResponse: Decodable {
    struct Body: Decodable { let matchedUser: User? }
    struct User: Decodable { let submitStatsGlobal: Stats }
    struct Stats: Decodable { let acSubmissionNum: [Entry] }
    struct Entry: Decodable {
        let difficulty: String
        let count: Int
    }

    let data: Body
}

private nonisolated struct CodewarsUser: Decodable {
    let honor: Int
}

private nonisolated struct StepikActivities: Decodable {
    struct Activity: Decodable { let pins: [Int] }

    let activities: [Activity]

    enum CodingKeys: String, CodingKey {
        case activities = "user-activities"
    }
}
