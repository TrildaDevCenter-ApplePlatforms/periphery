import Foundation

public enum OutputFormat: String, CaseIterable {
    case xcode
    case csv
    case json
    case checkstyle
    case codeclimate
    case githubActions = "github-actions"

    public static let `default` = OutputFormat.xcode

    @inlinable
    public var supportsAuxiliaryOutput: Bool {
        self == .xcode
    }
}
