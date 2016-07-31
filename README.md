# Commands

![Platform](https://img.shields.io/badge/platform-macos%20%7C%20linux-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-3.0--PREVIEW--3-yellowgreen.svg)
[![Build Status](https://travis-ci.org/evan-liu/Commands.svg)](https://travis-ci.org/evan-liu/Commands)

Command groups work together with [CommandArguments](https://github.com/evan-liu/CommandArguments). 

## Example

```swift

do {
  try Commands(name: "demo")
    .add(Clean.self, name: "clean")
    .add(Create.self, name: "create")
    .addGroup(name: "platform", desc: "platform commands") {
        $0.add(Platform.Add.self, name: "add")
    }
    .addGroup(name: "plugin") {
        $0.add(Plugin.Add.self, name: "add")
          .add(Plugin.Reset.self, name: "reset", desc: "Reset all plugins")
    }
    .run(Process.arguments.dropFirst())
} catch {
    print(error)
}

struct Clean: Runnable {
    func run(args: ArraySlice<String>) throws {
        // clean
    }
}

struct Create: RunnableWithArgs {
    struct Arguments: RunnableArguments {
        var name = Operand()
    }
    func run(argv: Arguments) throws {
        // create argv.name.value
    }
}

struct Platform {
    struct Add: RunnableWithArgs {
        struct Arguments: RunnableArguments {
            var name = Operand()
            var save = Flag()
        }
        func run(argv: Arguments) throws {
            // platform add argv.name.value
        }
    }
}

struct Plugin {
    struct Add: RunnableWithArgs {
        struct Arguments: RunnableArguments {
            var name = Operand()
            var save = Flag()
        }
        func run(argv: Arguments) throws {
            // plugin add argv.name.value
        }
    }
    struct Reset: Runnable {
        func run(args: ArraySlice<String>) throws {
            // plugin reset
        }
    }
}

```

## Install 

### Swift Package Manager: 

Add to dependencies: 

`.Package(url: "https://github.com/evan-liu/Commands.git", majorVersion: 0, minor: 1)`
