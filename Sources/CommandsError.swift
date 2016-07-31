import Foundation

public enum CommandsError: ErrorProtocol {
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
