import Foundation

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

struct FeedbackResponse: Codable {
    let success: Bool
    let message: String?
    let id: String?
    let error: String?
}

enum FeedbackError: Error, LocalizedError {
    case invalidResponse
    case serverError(Int)
    case encodingError
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .encodingError:
            return "Failed to encode request"
        case .networkError:
            return "Network error"
        }
    }
}

class FeedbackService {
    static let shared = FeedbackService()

    private let baseURL = "https://feedback-board.iocompile67692.workers.dev"
    private let appName = "SafeParents"

    private init() {}

    func submitFeedback(name: String, email: String, subject: String, message: String) async throws -> FeedbackResponse {
        let request = FeedbackRequest(
            name: name,
            email: email,
            subject: subject,
            message: message,
            app_name: appName
        )

        guard let url = URL(string: "\(baseURL)/api/feedback") else {
            throw FeedbackError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw FeedbackError.encodingError
        }

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw FeedbackError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FeedbackError.serverError(httpResponse.statusCode)
        }

        do {
            let feedbackResponse = try JSONDecoder().decode(FeedbackResponse.self, from: data)
            return feedbackResponse
        } catch {
            throw FeedbackError.invalidResponse
        }
    }
}
