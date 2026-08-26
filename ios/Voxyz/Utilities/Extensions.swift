import Foundation
import SwiftUI

private let iso8601Formatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    return f
}()

extension Date {
    var iso8601String: String {
        iso8601Formatter.string(from: self)
    }
}

extension String {
    var sanitizedTranscript: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

extension Color {
    static let voxyzPrimary = Color.blue
    static let voxyzSecondary = Color.gray
    static let voxyzAccent = Color.accentColor
}
