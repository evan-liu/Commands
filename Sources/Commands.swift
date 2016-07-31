import Foundation

public protocol Runnable {
    
    init()
    
    func run(args: ArraySlice<String>) throws
    
    func usage(commandName: String?) -> String
}

extension Runnable {
    public func usage(commandName: String?) -> String {
        return "Usage: \(commandName ?? "command")"
    }
}

public protocol RunnableGroup {
    
    @discardableResult
    func add(_ runnableType: Runnable.Type, name: String, desc: String?) -> Self
    
    @discardableResult
    func addGroup(name: String, desc: String?, block: (RunnableGroup)->Void) -> Self
}

extension RunnableGroup {
    @discardableResult
    public func add(_ runnableType: Runnable.Type, name: String) -> Self {
        return self.add(runnableType, name: name, desc: nil)
    }
    
    @discardableResult
    public func addGroup(name: String, block: (RunnableGroup)->Void) -> Self {
        return self.addGroup(name: name, desc: nil, block: block)
    }
}

public typealias UsagePrinter = (String) -> Void

public final class Commands {
    
    private let root:Group
    
    public init(name: String, desc: String? = nil, usagePrinter: UsagePrinter? = nil) {
        root = Group(name: name, desc: desc, usagePrinter: usagePrinter ?? { print($0) })
    }
    
    @discardableResult
    public func add(_ runnableType: Runnable.Type, name: String, desc: String? = nil) -> Self {
        root.add(runnableType, name: name, desc: desc)
        return self
    }
    
    @discardableResult
    public func addGroup(name: String, desc: String? = nil, block: (RunnableGroup)->Void) -> Self {
        root.addGroup(name: name, desc: desc, block: block)
        return self
    }
    
    public func run(args: ArraySlice<String>) throws {
        try root.run(args: args)
    }
    
    public func printUsage() {
        root.printUsage()
    }
    
}

// ----------------------------------------
// MARK: Private
// ----------------------------------------
private class CommandsElement {
    let name: String
    let desc: String?
    let parent:Group?
    let usagePrinter: UsagePrinter
    
    init(name: String, desc: String?, usagePrinter: UsagePrinter, parent:Group? = nil) {
        self.name = name
        self.desc = desc
        self.usagePrinter = usagePrinter
        self.parent = parent
    }
    
    func run(args: ArraySlice<String>) throws {
    }
    
    func synopsis(depth: Int) -> String {
        return synopsisTitle(depth: depth)
    }
    
    func synopsisTitle(depth: Int) -> String {
        let title = indent(depth: depth) + name
        if let desc = desc {
            return "\(title): \(desc)"
        } else {
            return title
        }
    }
    
    func indent(depth: Int) -> String {
        return String(repeating: " " as Character, count: depth * 2)
    }
    
    func isHelp(_ args: ArraySlice<String>) -> Bool {
        return args.count == 1 && ["help", "-h", "--help"].contains(args.last!)
    }
    
    var path: String {
        return joinAncestors(toPath: [name]).joined(separator: " ")
    }
    
    func joinAncestors(toPath path: [String]) -> [String] {
        guard let parent = parent else { return path }
        return parent.joinAncestors(toPath: [parent.name] + path)
    }
}

private final class Command: CommandsElement {
    let runnableType: Runnable.Type
    
    init(runnableType: Runnable.Type, name: String, desc: String?, usagePrinter: UsagePrinter, parent:Group) {
        self.runnableType = runnableType
        super.init(name: name, desc: desc, usagePrinter: usagePrinter, parent: parent)
    }
    
    override func run(args: ArraySlice<String>) throws {
        let runnable = runnableType.init()
        if isHelp(args) {
            usagePrinter(runnable.usage(commandName: path))
        } else {
            try runnable.run(args: args)
        }
    }
}

private final class Group: CommandsElement, RunnableGroup {
    var children = [CommandsElement]()
    
    @discardableResult
    func add(_ runnableType: Runnable.Type, name: String, desc: String?) -> Self {
        children.append(Command(runnableType: runnableType, name: name, desc: desc, usagePrinter: usagePrinter, parent: self))
        return self
    }
    
    @discardableResult
    func addGroup(name: String, desc: String?, block: (RunnableGroup)->Void) -> Self {
        let group = Group(name: name, desc: desc, usagePrinter: usagePrinter, parent: self)
        block(group)
        children.append(group)
        return self
    }
    
    override func run(args: ArraySlice<String>) throws {
        if args.count == 0 || isHelp(args) { return printUsage() }
        
        let name = args.first!
        for child in children {
            if child.name == name {
                try child.run(args: args.dropFirst())
                return
            }
        }
        
        throw CommandsError.notFound
    }
    
    private func printUsage() {
        let path = self.path
        var lines = [String]()
        if let desc = desc {
            lines += [desc, ""]
        }
        lines += [
            "Usage: \(path) [command] [options] [operands]",
            "",
            "Commands:"
        ]
        lines += children.map { $0.synopsis(depth: 1) }
        lines += [
            "",
            "Command usage: ",
            "  \(path) [command] --help"
        ]
        usagePrinter(lines.joined(separator: "\n"))
    }
    
    private override func synopsis(depth: Int) -> String {
        let lines = [synopsisTitle(depth: depth)] + children.map { $0.synopsis(depth: depth + 1) }
        return lines.joined(separator: "\n")
    }
}
