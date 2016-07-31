import Foundation
import CommandArguments

public protocol RunnableArguments: CommandArguments {
    init()
}

public protocol RunnableWithArgs: Runnable {
    associatedtype Arguments: RunnableArguments
    
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
