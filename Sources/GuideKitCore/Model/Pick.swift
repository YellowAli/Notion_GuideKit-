import Foundation

/// Chooses among several views that share one guide ID, in layout (tree) order.
public enum Pick: String, Codable, Sendable {
    /// Highlight the first matching view.
    case first
    /// Highlight the last matching view.
    case last
}
