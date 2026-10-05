import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .server(_, let message):
            return message ?? "Something went wrong. Please try again."
        case .decoding:
            return "We couldn't read the server's response."
        case .transport:
            return "Couldn't connect. Check your internet connection."
        }
    }
}
