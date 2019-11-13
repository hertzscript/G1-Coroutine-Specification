HertzScript Systems Specification
=================================

**WORK IN PROGRESS**

Todo: Add sequence and dependency graphs.

# High-Level Synopsis

HertzScript (abbreviated "HzScript") automatically transforms JavaScript functions into stackless coroutines which can be preempted, and provides a degree of concurrency which is more fine-grained than what you get with traditional JavaScript. Normally functions must run from beginning to end due to the single-threaded nature of JavaScript, but HertzScript automatically pauses and context switches between several functions mid-execution. Software developers may utilize HertzScript's concurrency via a new `spawn` keyword. If you call a function which is preceded by the `spawn` keyword, then the function will run concurrently alongside any other functions and the caller function.

Coroutines are normally reserved for cooperative multitasking and have to be manually implemented by software developers, requiring them to manage control yielding and reentry points. HertzScript implements voluntary preemptive multitasking which is a compiler-managed variant of cooperative multitasking, and it does not require the developer to manually implement control yielding or reentry points.

# Reference Systems & Supporting Technologies

- [HertzScript Compiler](https://github.com/hertzscript/Compiler)
	- [Babel](https://babeljs.io/)
	- [Acorn](https://github.com/acornjs/acorn)
	- [marktail](https://github.com/Floofies/marktail)
- [HertzScript Virtual Machine](https://github.com/hertzscript/VirtualMachine)
- [HertzScript Multitasking Dispatcher](https://github.com/hertzscript/Dispatcher)
- [HertzScript Multiprocessing Isolate](https://github.com/hertzscript/Isolate)
- [HertzScript Programming Environment](https://github.com/hertzscript/Environment)

# Overview of Components

HertzScript is composed of layered abstracting and interoperating systems including a compiler, virtual machine, multitasking dispatcher, and programming environment. Each component can be used either independently or as part of a higher-level abstracting component. The lowest-level foundational components are the compiler and the virtual machine.

![Component Diagram](http://g.gravizo.com/svg?
	digraph Components {
		Compiler [shape=box];
		VirtualMachine [shape=box];
		Dispatcher [shape=box];
		Environment [shape=box];
		Compiler -> VirtualMachine;
		VirtualMachine -> Dispatcher;
		Dispatcher -> Environment;
		{
			rank=same; Compiler VirtualMachine Dispatcher Environment
		}
	}
)

# Literal Value Notation & Data Types

Specific conventions for the notation of typed literal values are defined here and are used throughout this specification. Some special characters indicated within this section are Markdown terminal characters.

Notating a literal value with a specific data type may require the prefixing and/or postfixing of specific characters.

When contributing to this specification's Markdown documents via a text editor, each reference to a literal value requires grave accents to be the outermost prefix and postfix: \` (`U+0060`)

The below table illustrates the following for each data type:

- The name of the data type.
- Special characters and their Unicode charcodes in parentheses.
- The positions at which special characters should be located relative to the literal value.
- An unformatted Markdown example which a reader would observe in a plain-text editor.
- A formatted example which a reader would observe when viewing the rendered distribution of this specification.

Type|Characters|Position of Characters|Unformatted Example|Formatted Example
----------------------------------------------------------------------------
Identifier | None | None | \`name\` | `name`
Object | `Object` | Prefix | Object \`name\` | Object `name`
Nested Property Key Value | Full Stop: `.` (`U+002E`) | Between Property Keys | \`name1.name2\` | `name1.name2`
Symbol | Commercial At: `@` (`U+0040`) | Prefix | \`@name\` | `@name`
`TokenLib` Symbol | 2x Commercial At: `@@` (`U+0040`) | Prefix | \`@@name\` | `@@name`
String | Quotation Mark: `"` (`U+0022`) | Prefix & Postfix | \`"string"\` | `"string"`
Boolean | None | None | \`true\` | `true`
Integer | None | None | \`123\` | `123`
Float | Full Stop: `.` (`U+002E`) | Anywhere | \`12.34\` | `12.34`
Negative Integer | Minus Sign: `-` (`U+2212`) | Prefix | \`-123\` | `-123`
Negative Float | Minus Sign: `-` (`U+2212`) | Prefix | \`-12.34\` | `-12.34`
Null | None | None | \`null\` | `null`
Undefined | None | None | \`undefined\` | `undefined`

## Object

Objects are logical collections of properties. Each property associates a key value with an arbitrary value of any data type.

Property key values can be used to access or assign properties and their associated arbitrary values.

Dynamic property key values are equal to any value referred to by an Identifier, and can be used to access or assign properties and their associated arbitrary values.

Nested properties may be notated in short-form such that a Full Stop or period may be placed between each property key value.

Objects must be prefixed with the word "Object".

## Symbol

Symbols are uniqueness types, meaning every symbol is immutable and unique. Symbols are used as dynamic property keys for Objects.

Symbols are prefixed by a single "commercial at" characer.

A Symbol that is created by and is a member of [`TokenLib.symbols`](#sec-TokenLib) is prefixed by two "commercial at" characters.

## String

Strings are finite ordered sequences of zero or more 16-bit unsigned integer values.

Strings must be both prefixed and postfixed by quotation marks.

## Boolean

Booleans must be equal to one of two different values: `true` or `false`.

## Integer

Integers are whole numbers represented by double-precision 64-bit binary format IEEE 754-2008 values.

Integers which are negative must be notated with a minus sign prefix. Integers which both non-terminating and infinitely large must be notated with `Infinity`, or `-Infinity` for negative numbers.

## Float

Floats are non-whole numbers which are represented by double-precision 64-bit binary format IEEE 754-2008 values.

Floats which are negative must be notated with a minus sign prefix.

## Null

`null` is unchangeable and is always equal to `null`.

## Undefined

`undefined` is unchangeable and is always equal to `undefined`.

# Compiler

The HertzScript compiler transforms function calls into yielded instances of `InstructionToken` such that all transformed function calls are made in reverse upon script execution.

The HertzScript compiler uses a multi-stage source-to-source compilation process to transform JavaScript functions into instruction streams; all functions within a HzScript program are GeneratorFunctions which yield instructions. Residing the bottom abstraction level of the system, the HertzScript compiler serves as a fundamental mechanism in the creation of re-entrant programs.

The first stage in the compilation process consists of Acorn, an Acorn parser plugin, and Acorn-Walk, which are used to parse and transform any `SpawnExpression` to a regular method call for Babel to recognize in the second stage. `spawn` is a contextual keyword which could also be a regular method call and not a `SpawnExpression`, so the parser looks for any instance of the `spawn` keyword followed by any number of spaces and an identifier character.

The second stage consists of Babel and a Babel transformation plugin which is used to transform all function expressions/statements into GeneratorFunctions, and wrap all functions in detour hooking functions. Within the new GeneratorFunctions all CallExpressions, NewExpressions, ReturnStatements, YieldExpressions, and SpawnExpressions are transformed into yielded instruction tokens. A special token named `loopYield` is added to the beginning of each loop to ensure that they are interruptable.

## Transformation Functions

### HzCoroutine



## Visitor Functions

### CallExpression

# VirtualMachine

The `VirtualMachine` class sequentially executes a single `InstructionToken` stream as a SISD computer processor architecture, and implements computational behaviors as indicated by each `InstructionToken`. `VirtualMachine` may consume both `InstructionToken` Object instances and context-sensitive data.

`VirtualMachine` changes how the JavaScript virtual machine call stack is utilized. When a new coroutine is started, a new `ControlBlock` class instance is created for it which contains a virtual call stack, and the HertzScript instruction set corresponds with operations which push and pop the coroutines in that stack. Only the currently executing coroutine will reside within the JavaScript VM call stack. The JavaScript VM call stack does not grow past the currently running coroutine except during function calls which were initiated by many of JavaScript's standard operators which are not the invocation operator, loosely limiting the VM call stack to a set length. The end result of this size reduction is that all coroutines are generally able to perform a context switch with `O(1)` time complexity, significantly reducing any possible jitter that would critically impact multitasking operations.

## Execution Cycle

The core execution cycle is called the Fetch-Coerce-Execute cycle, or FCE cycle. The FCE cycle's programming style and construction is that of Aspect-Oriented Programming. The FCE Functions are `FetchInstruction`, `CoerceInstruction`, and `ExecuteInstruction`; the `VirtualMachine` constructor submits the three FCE Functions to an `AspectWeaver` instance. The `AspectWeaver` instance is given three Pointcuts labaled with the Strings `"fetch"`, `"coerce"`, and `"execute"`. The labeled Pointcuts expose six Joinpoints in total, such that Functions may be added or removed at six logical points in the control flow before or after each of the three FCE Functions.

## Constructor

VirtualMachine(uTokenLib = null) :
1. If `uTokenLib` is strictly equal to `null`, then
  * Let `this.tokenLib` be `uTokenLib`.
1. Else let `this.tokenLib` be a new instance of class `TokenLib`;
1. Let `this.detourLib` be a new instance of class `DetourLib` with arguments `VirtualMachine` and `this.tokenLib`.
1. Let `this.userLib` be a new instance of class `UserLib` with arguments `this.tokenLib` and `this.detourLib`.
1. Let `this.controlBlock` be a new instance of class `ControlBlock` with arguments `this.tokenLib`.
1. Let `this.lastError` be `this.tokenLib.symbols.nullSym`.
1. Let `this.lastRemit` be `this.tokenLib.symbols.nullSym`.
1. Let `this.lastInstruction` be `null`.
1. Let `this.terminated` be `false`.
1. Let `instructions` be new instance of class `Object`.
  * Let `instructions.enqueue` be `this._enqueue`.
  * Let `instructions.import` be Array< `this._import` >.
  * Let `instructions.terminate` be `this._terminate`.
  * Let `instructions.vmError` be `this._vmError`.
  * Let `instructions.programError` be `this._programError`.
  * Let `instructions.fetch` be `this._fetch`.
  * Let `instructions.coerce` be `this._coerce`.
  * Let `instructions.execute` be `this._execute`.
  * Let `instructions.cycle` be `this._cycle`.
  * Let `instructions.cycleAsync` be `this._cycleAsync`.
1. Let `this.weaver` be a new instance of class `AspectWeaver` with arguments `this` and `instructions`.

## AspectWeaver

The `AspectWeaver` class is an Aspect-oriented program control system which is designed to allow the sequential execution, addition, mutation, and removal of Functions during run-time. Points at which functions may be added or removed are called Joinpoints, whereas the problem domains which Joinpoints implement are called Pointcuts.



## Execution Cycle

The `VirtualMachine` constructor creates a new instance the `AspectWeaver` class and populates it with three distinct Pointcuts: Fetch, Coerce, and Execute.

## DetourLib

The Babel transformation plugin wraps all function declarations and expressions in detouring functions, and the detour library is a collection of function hooks designed to detour specific types of functions.

Detour functions insert a hooking function which replaces the original function with a special invocation adapter. Upon invoking the adapter a new HertzScript virtual machine is started in-place, and the original function is run from within it. The original function is assigned to a Symbol property named `tokenSym`. Each hooking function marks the detour function and original function with special marker Symbols which allow the virtual machine to observe information which would originally only be visible at compile-time.

The below figure illustrates the path of control flow from a caller function to the original function after it has been detoured.

![Component Diagram](http://g.gravizo.com/svg?
	digraph Components {
		Caller [shape=circle];
		Detour [shape=box];
		VirtualMachine [shape=box];
		tokenSym [shape=box];
		Function [shape=box];
		VirtualMachine [shape=box];
		Caller -> Detour;
		Detour -> tokenSym [style=dotted] [arrowhead=empty];
		Detour -> VirtualMachine;
		VirtualMachine -> tokenSym;
		tokenSym -> Function;
		{
			rank=same; Caller Detour VirtualMachine;
		}
		{
			rank=same; tokenSym Function
		}
	}
)

### Detour Hooking Functions

Name|Arguments|Description
--------------------------
`hookCoroutine` |  | Detours a function.
`hookArrowCoroutine` detours an `ArrowFunctionExpression`.
`hookGenerator` detours a `GeneratorFunction`.
`hookIterator` detours an iterator interface object's `next`, `return`, and `throw` methods.

## Kernelizer

The `Kernelizer` class is a very simple object which assigns arbitrary values directly to itself. This class serves as the base class for the `InstructionToken` class.

Strings given as an argument list to the constructor indicate the labels of arguments given in an Array via the `set` method, and can be reset with an arbitrary value via the `reset` method.

### Constructor

Assigns undefined to all properties ordered via an argument list of Strings spread to Array `argsArray`.

Kernelizer(...argsArrray) :
1. Let value of property `argSlots` of `this` be `argsArray`.
1. Invoke `this.reset()`.

### Prototype Methods

#### reset

Assigns an arbitrary value `resetValue` to all properties ordered via Strings in Array `this.argSlots`.

Kernelizer.prototype.reset(resetValue) :
1. If `this.argSlots.length` is strictly equal to `0`, then
  * Return `this`.
1. For each `argName` of Array `this.argSlots`, do
  * Let value of dynamic property `argName` of `this` be `resetValue`.
1. Return `this`.


#### set

Assigns arbitrary values in Array `argsArray` to properties ordered via Strings in Array `this.argSlots`

Kernelizer.prototype.set(argsArray) :
1. If `this.argSlots.length` is strictly equal to `0`, then
  * Return `this`.
  * Let `loc` be `0`.
1. For each `argName` of `this.argSlots`, do
  * If Number `loc` is less than or equal to Number `argsArray.length`, then
     * Let value of dynamic property `argName` of `this` be the value of dynamic property `loc` of `argsArray`.
  * Else let value of dynamic property `argName` of `this` be undefined.
  * Increment Number `loc` by `1`.
1. Return `this`.

## InstructionToken

The `InstructionToken` class extends the `Kernelizer` class by assigning String `type` and Symbol `kernSym` to itself.

### Constructor

InstructionToken(type, kernSym, ...argsArrray) :
1. Let `kern` be a new instance of class `Kernelizer`.
1. Let value of property `type` of `kern` be `type`.
1. Let value of dynamic property `kernSym` of `kern` be `true`.
1. Return `kern`.

## TokenLib

`TokenLib` is a class which creates and contains `InstructionToken` instances and marker Symbols.

`InstructionToken` instances are designed to safely encapsulate userspace data such as functions and their input operands, return/yield values, or no data. All `InstructionToken` instances are marked by having a special symbol assigned to them called `kernSym`; if `VirtualMachine` determines that an object has the symbol as a property, then it assumes that the object is an `InstructionToken` and attempts to process it.

Each `InstructionToken` is a single-instance uniqueness type to reduce memory overhead, because all instances are gauranteed to be thread-safe and free of race conditions. Because the virtual machine executes in a single thread, each unique `InstructionToken` instance will be used atomically during a single `VirtualMachine` fetch-decode-execute cycle.

### Object Methods

#### isKernelized

Returns a Boolean which indicates whether or not `input` is an Object instance of either the `InstructionToken` class or the `Kernelizer` class.

isKernelized(input) :
1. If the result of unary expression `typeof` with argument `input` is strictly equal to `"object"`, then
  * Return the result of searching for property `@@kernSym` in `input`.
1. Else return Boolean `false`.

### Object Properties

#### tokens

Name|Arguments|Description
--------------------------
`loopYield` | None | Yield control flow to `VirtualMachine`.
`call` | Array< Function `functor`, Boolean `isTailCall` > | Invoke a function.
`callArgs` | Array< Function `functor`, Array `args`, Boolean `isTailCall` > | Invoke a function with arguments.
`callMethod` | Array< Object `object`, Any `property`, Boolean `isTailCall` > | Invoke an Object method function.
`callMethodArgs` | Object `object`, Any `property`, Array `args`, Boolean `isTailCall` > | Invoke an Object method function with arguments.
`new` | Array< Function `functor` > | Invoke a constructor.
`newArgs` | Array< Function `functor`, Array `args` > | Invoke a constructor with arguments.
`newMethod` | Array< Object `object`, Any `property` > | Invoke a constructor Object method function.
`newMethodArgs` | Array< Object `object`, Any `property`, Array `args` > | Invoke a constructor Object method function with arguments.
`spawn` | Array< Function `functor` > | Queue a coroutine for later execution.
`spawnArgs` | Array< Function `functor`, Array `args` > | Queue a coroutine for later execution with arguments.
`spawnMethod` | Array< Object `object`, Any `property` > | Queue an Object method coroutine for later execution.
`spawnMethodArgs` | Array< Object `object`, Any `property`, Array `args` > | Queue an Object method coroutine for later execution with arguments.
`return` | None | Perform a `return` statement.
`returnValue` | Array< Any `arg` > | Perform a `return` statement with a value.
`yield` | None | Perform a `yield` expression.
`yieldValue` | Array< Any `arg` > | Perform a `yield` expression with a value.

#### symbols

Name|Value|Description
----------------------
`tokenSym` | Function | Is assigned to the userspace Function of a coroutine.
`crtSym` | Any | Marks the function it is assigned to as being a coroutine.
`conSym` | Any | Marks the function it is assigned to as being coroutine.
`genSym` | Any | Marks the function it is assigned to as being generator.
`iterSym` | Any | Marks the function it is assigned to as being assigned to an iterator interface object.

## UserLib


# Dispatcher

The HertzScript dispatcher is a concurrency control system and preemptive multitasking kernel. The dispatcher is responsible for the supervision, scheduling, dispatchment, preemption, and context switching of multiple different HertzScript virtual machines within a single thread.


# Programming Environment


TBD
