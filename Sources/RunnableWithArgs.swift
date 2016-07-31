import Foundation
import CommandArguments

/// `Arguments` type can be created with `init()`.
public protocol RunnableArguments: CommandArguments {
    init()
}

/// `Runnable` type with associated `RunnableArguments`.
public protocol RunnableWithArgs: Runnable {
    
    /// `Arguments` type can be created with `init()`.
    associatedtype Arguments: RunnableArguments
    
    /// Run with created and parsed `Arguments`.
    func run(argv: Arguments) throws
}

extension RunnableWithArgs {
    
    public func run(args: ArraySlice<String>) throws {
        var argv = Arguments.init()
        try argv.parse(args)
        try run(argv: argv)
    }
    
    public func usage(commandName: String? = nil) -> String {
        return Arguments.init().usage(commandName: commandName)
    }
    
}
