import Foundation

/// Errors throws when call `Commands.run()`.
public enum CommandsError: ErrorProtocol {
    
    /// Command not found (invalid name or path).
    case notFound
}

extension CommandsError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notFound:
            return "command not found"
        }
    }
    
}
