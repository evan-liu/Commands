import Foundation

public protocol Runnable {
    
    init()
    
    func run(args: ArraySlice<String>) throws
    
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
private protocol CommandsElement {
    var name: String { get }
    var desc: String? { get }
    
    func synopsis(depth: Int) -> String
    
    func run(args: ArraySlice<String>) throws
}

extension CommandsElement {
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
}

private final class Command: CommandsElement {
    let name: String
    let desc: String?
    let runnableType: Runnable.Type
    
    init(runnableType: Runnable.Type, name: String, desc: String?) {
        self.runnableType = runnableType
        self.name = name
        self.desc = desc
    }
    
    func run(args: ArraySlice<String>) throws {
        let runnable = runnableType.init()
        try runnable.run(args: args)
    }
}

private final class Group: CommandsElement, RunnableGroup {
    let name: String
    let desc: String?
    let parent:Group?
    var children = [CommandsElement]()
    
    let usagePrinter: UsagePrinter
    init(name: String, desc: String?, usagePrinter: UsagePrinter, parent:Group? = nil) {
        self.name = name
        self.desc = desc
        self.usagePrinter = usagePrinter
        self.parent = parent
    }
    
    @discardableResult
    func add(_ runnableType: Runnable.Type, name: String, desc: String?) -> Self {
        children.append(Command(runnableType: runnableType, name: name, desc: desc))
        return self
    }
    
    @discardableResult
    func addGroup(name: String, desc: String?, block: (RunnableGroup)->Void) -> Self {
        let group = Group(name: name, desc: desc, usagePrinter: usagePrinter, parent: self)
        block(group)
        children.append(group)
        return self
    }
    
    func run(args: ArraySlice<String>) throws {
        if isHelp(args) { return printUsage() }
        
        let name = args.first!
        for child in children {
            if child.name == name {
                try child.run(args: args.dropFirst())
                return
            }
        }
        
        throw CommandsError.notFound
    }
    
    private func isHelp(_ args: ArraySlice<String>) -> Bool {
        if args.count == 0 { return true }
        return args.count == 1 && ["help", "-h", "--help"].contains(args.last!)
    }
    
    private func printUsage() {
        let path = getPath([name])
        let lines = [
            "Usage: " + path.joined(separator: " ") + " [command]",
            "",
            "Commands:"
        ] + children.map { $0.synopsis(depth: 1) }
        usagePrinter(lines.joined(separator: "\n"))
    }
    
    private func getPath(_ path: [String]) -> [String] {
        guard let parent = parent else {
            return path
        }
        return parent.getPath([parent.name] + path)
    }
    
    private func synopsis(depth: Int) -> String {
        let lines = [synopsisTitle(depth: depth)] + children.map { $0.synopsis(depth: depth + 1) }
        return lines.joined(separator: "\n")
    }
}
