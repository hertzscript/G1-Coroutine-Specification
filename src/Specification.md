HertzScript Systems Specification
=================================

**WORK IN PROGRESS**

Todo: Add sequence and dependency graphs.

# High-Level Synopsis

HertzScript (abbreviated "HzScript") automatically transforms JavaScript functions into stackless coroutines which can be preempted, and provides a degree of concurrency which is more fine-grained than what you get with traditional JavaScript. Normally functions must run from beginning to end due to the single-threaded nature of JavaScript, but HertzScript automatically pauses and context switches between several functions mid-execution. Software developers may utilize HertzScript's concurrency via a new `spawn` keyword. If you call a function which is preceded by the `spawn` keyword, then the function will run concurrently alongside any other functions and the caller function.

Coroutines are normally reserved for cooperative multitasking and have to be manually implemented by software developers, requiring them to manage control yielding and reentry points. HertzScript implements voluntary preemptive multitasking which is a compiler-managed variant of cooperative multitasking, and it does not require the developer to manually implement control yielding or reentry points.

## Overview of Components

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

# Compiler

The HertzScript compiler transforms function calls into yielded instances of `InstructionToken` such that all transformed function calls are made in reverse upon script execution.

The HertzScript compiler uses a multi-stage source-to-source compilation process to transform JavaScript functions into instruction streams; all functions within a HzScript program are GeneratorFunctions which yield instructions. Residing the bottom abstraction level of the system, the HertzScript compiler serves as a fundamental mechanism in the creation of re-entrant programs.

The first stage in the compilation process consists of Acorn, an Acorn parser plugin, and Acorn-Walk, which are used to parse and transform any `SpawnExpression` to a regular method call for Babel to recognize in the second stage. `spawn` is a contextual keyword which could also be a regular method call and not a `SpawnExpression`, so the parser looks for any instance of the `spawn` keyword followed by any number of spaces and an identifier character.

The second stage consists of Babel and a Babel transformation plugin which is used to transform all function expressions/statements into GeneratorFunctions, and wrap all functions in detour hooking functions. Within the new GeneratorFunctions all CallExpressions, NewExpressions, ReturnStatements, YieldExpressions, and SpawnExpressions are transformed into yielded instruction tokens. A special token named `loopYield` is added to the beginning of each loop to ensure that they are interruptable.

## Transformation Functions

### HzCoroutine



## Visitor Functions

### CallExpression



# DetourLib

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

## Detour Hooking Functions

Name|Arguments|Description
--------------------------
`hookCoroutine` |  | Detours a function.
`hookArrowCoroutine` detours an `ArrowFunctionExpression`.
`hookGenerator` detours a `GeneratorFunction`.
`hookIterator` detours an iterator interface object's `next`, `return`, and `throw` methods.

# Kernelizer

The `Kernelizer` class is a very simple object which assigns arbitrary values directly to itself. This class serves as the base class for the `InstructionToken` class.

Strings given as an argument list to the constructor indicate the labels of arguments given in an Array via the `set` method, and can be reset with an arbitrary value via the `reset` method.

## Constructor

Assigns undefined to all properties ordered via an argument list of Strings spread to Array `argsArray`.

Kernelizer(...argsArrray) :
1. Let property `argSlots` of `this` be `argsArray`.
1. Invoke `this.reset()`.

## Prototype Methods

### reset

Assigns an arbitrary value `resetValue` to all properties ordered via Strings in Array `this.argSlots`.

Kernelizer.prototype.reset(resetValue) :
1. If `this.argSlots.length` is strictly equal to Number `0`, then
  * Return `this`.
1. For each `argName` of Array `this.argSlots`, do
  * Let dynamic property `argName` of `this` be `resetValue`.
1. Return `this`.


### set

Assigns arbitrary values in Array `argsArray` to properties ordered via Strings in Array `this.argSlots`

Kernelizer.prototype.set(argsArray) :
1. If `this.argSlots.length` is strictly equal to Number `0`, then
  * Return `this`.
  * Let `loc` be Number `0`.
1. For each `argName` of `this.argSlots`, do
  * If Number `loc` is less than or equal to Number `argsArray.length`, then
     * Let dynamic property `argName` of `this` be the value of dynamic property `loc` of `argsArray`.
  * Else let dynamic property `argName` of `this` be undefined.
  * Increment Number `loc` by Number `1`.
1. Return `this`.

# InstructionToken

The `InstructionToken` class extends the `Kernelizer` class by assigning String `type` and Symbol `kernSym` to itself.

## Constructor

InstructionToken(type, kernSym, ...argsArrray) :
1. Let `kern` be a new instance of class `Kernelizer`.
1. Let property `type` of `kern` be `type`.
1. Let dynamic property `kernSym` of `kern` be Boolean `true`.
1. Return `kern`.

# TokenLib

`TokenLib` is a class which creates and contains `InstructionToken` instances and marker Symbols.

`InstructionToken` instances are designed to safely encapsulate userspace data such as functions and their input operands, return/yield values, or no data. All `InstructionToken` instances are marked by having a special symbol assigned to them called `kernSym`; if `VirtualMachine` determines that an object has the symbol as a property, then it assumes that the object is an `InstructionToken` and attempts to process it.

Each `InstructionToken` is a single-instance uniqueness type to reduce memory overhead, because all instances are gauranteed to be thread-safe and free of race conditions. Because the virtual machine executes in a single thread, each unique `InstructionToken` instance will be used atomically during a single `VirtualMachine` fetch-decode-execute cycle.

## Object Methods

### isKernelized

Returns a Boolean which indicates whether or not `input` is an Object instance of either the `InstructionToken` class or the `Kernelizer` class.

isKernelized(input) :
1. Let `left` be the result of unary expression `typeof` with argument `input`.
1. If `left` is strictly equal to String `object`, then
  * Let `right` be the result of searching for property Symbol `kernSym` in `input`.
  * If `right` is strictly equal to Boolean `true`, then
    * Return Boolean `true`.
  * Else return Boolean `false`.
1. Else return Boolean `false`.

## Object Properties

### tokens

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

### symbols

Name|Value|Description
----------------------
`tokenSym` | Function | Is assigned to the userspace Function of a coroutine.
`crtSym` | Any | Marks the function it is assigned to as being a coroutine.
`conSym` | Any | Marks the function it is assigned to as being coroutine.
`genSym` | Any | Marks the function it is assigned to as being generator.
`iterSym` | Any | Marks the function it is assigned to as being assigned to an iterator interface object.

# UserLib


# VirtualMachine

To facilitate the aforementioned instruction stream transformations while preserving normal JavaScript execution, the HertzScript virtual machine implements the behaviors indicated by the instruction set and executes the compiled source code. The HertzScript virtual machine is written in regular JavaScript and executes within the JavaScript virtual machine userspace.


The HertzScript virtual machine consumes instruction tokens and performs the operations indicated by them.
The HertzScript virtual machine changes how the JavaScript virtual machine call stack is utilized. When a new coroutine is started, a new Coroutine Control Block is created for it which contains a virtual call stack, and the HertzScript instruction set corresponds with operations which push and pop the coroutines in that stack. Only the currently executing coroutine will reside within the JavaScript VM call stack.

The JavaScript VM call stack does not grow past the currently running coroutine except during function calls which were initiated by many of JavaScript's standard operators which are not the invocation operator, loosely limiting the VM call stack to a set length. The end result of this size reduction is that all coroutines are generally able to perform a context switch with `O(1)` time complexity, significantly reducing any possible jitter that would critically impact multitasking operation.

# Dispatcher

The HertzScript dispatcher is a concurrency control system and preemptive multitasking kernel. The dispatcher is responsible for the supervision, scheduling, dispatchment, preemption, and context switching of multiple different HertzScript virtual machines within a single thread.


# Programming Environment


TBD
