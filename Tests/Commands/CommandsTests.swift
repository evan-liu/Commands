import XCTest
import Commands
import CommandArguments

class CommandsTests: XCTestCase {
    
    static let allTests = [
        ("testCommands", testCommands)
    ]
    
    static var runData:[String]!
    
    override func setUp() {
        CommandsTests.runData = []
    }
    
    struct Clean: Runnable {
        func run(args: ArraySlice<String>) throws {
            CommandsTests.runData.append("clean")
        }
    }
    
    struct Create: RunnableWithArgs {
        struct Arguments: RunnableArguments {
            var name = Operand()
        }
        func run(argv: Arguments) throws {
            CommandsTests.runData.append("create \(argv.name.value!)")
        }
    }
    
    struct Platform {
        struct Add: RunnableWithArgs {
            struct Arguments: RunnableArguments {
                var name = Operand()
                var save = Flag()
            }
            func run(argv: Arguments) throws {
                CommandsTests.runData.append("platform add \(argv.name.value!) --save=\(argv.save.value)")
            }
        }
    }
    
    struct Plugin {
        struct Add: RunnableWithArgs {
            struct Arguments: RunnableArguments {
                var name = Operand(usage: "plugin name")
                var save = Flag(usage: "if save to package config")
            }
            func run(argv: Arguments) throws {
                CommandsTests.runData.append("plugin add \(argv.name.value!) --save=\(argv.save.value)")
            }
        }
        struct Reset: Runnable {
            func run(args: ArraySlice<String>) throws {
                CommandsTests.runData.append("plugin reset")
            }
        }
    }
    
    func testCommands() {
        var usage: String = ""
        let commands = Commands(name: "test", desc: "test commands", usagePrinter: { usage = $0 })
            .add(Clean.self, name: "clean")
            .add(Create.self, name: "create")
            .addGroup(name: "platform", desc: "platform commands") {
                $0.add(Platform.Add.self, name: "add")
            }
            .addGroup(name: "plugin") {
                $0.add(Plugin.Add.self, name: "add")
                    .add(Plugin.Reset.self, name: "reset", desc: "Reset all plugins")
            }
        
        //-- usage
        commands.printUsage()
        XCTAssert(usage.contains("    reset: Reset all plugins"))
        
        _ = try? commands.run(args: ["test", "platform", "--help"].dropFirst())
        XCTAssert(usage.contains("Usage: test platform [command]"))
        
        _ = try? commands.run(args: ["test", "plugin", "-h"].dropFirst())
        XCTAssert(usage.contains("  reset: Reset all plugins"))
        
        _ = try? commands.run(args: ["test", "clean", "help"].dropFirst())
        XCTAssert(usage.contains("test clean"))
        
        //-- run
        _ = try? commands.run(args: ["test", "clean"].dropFirst())
        XCTAssertEqual(CommandsTests.runData.last, "clean")
        
        _ = try? commands.run(args: ["test", "create", "app"].dropFirst())
        XCTAssertEqual(CommandsTests.runData.last, "create app")
        
        _ = try? commands.run(args: ["test", "platform", "add", "ios"].dropFirst())
        XCTAssertEqual(CommandsTests.runData.last, "platform add ios --save=false")
        
        _ = try? commands.run(args: ["test", "plugin", "add", "files", "--save"].dropFirst())
        XCTAssertEqual(CommandsTests.runData.last, "plugin add files --save=true")
        
        _ = try? commands.run(args: ["test", "plugin", "reset"].dropFirst())
        XCTAssertEqual(CommandsTests.runData.last, "plugin reset")
        
        _ = try? commands.run(args: ["test", "plugin", "add", "--help"].dropFirst())
        XCTAssert(usage.contains("Options:"))
        
        //-- throws
        do {
            try commands.run(args: ["test", "xxx"].dropFirst())
            XCTFail()
        } catch {
            XCTAssertEqual("\(error)", "command not found")
        }
    }
    
}
