HertzScript Systems Specification
--------------------------------

**WORK IN PROGRESS**

Todo: Add sequence and dependency graphs.

# High-Level Synopsis

HertzScript (abbreviated "HzScript") transforms JavaScript functions into stackless coroutines which can be preempted, and provides a degree of concurrency which is more fine-grained than traditional JavaScript. Normal functions must run from beginning to end due to the single-threaded nature of JavaScript, but HertzScript allows you to automatically preempt and context switch between several functions; software developers may utilize this concurrency via a new `spawn` keyword. If you call a function which is preceded by the `spawn` keyword, then the function will run concurrently alongside any other functions and the caller function.

Coroutines are normally reserved for cooperative multitasking, but HertzScript implements a special variant called voluntary preemptive multitasking. In regular cooperative programs the software developer must manually declare the points at which programs will yield, and HertzScript extends that concept by automating it at every function call and loop.

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

# Theory of Operation

## Compiler

The HertzScript compiler uses a multi-stage source-to-source compilation pipeline to transform JavaScript functions into instruction streams; all functions within a HzScript program are GeneratorFunctions which yield instructions. Residing the bottom abstraction level of the system, the HertzScript compiler serves as a fundamental mechanism in the creation of re-entrant programs.

The first stage in the compilation pipeline consists of Acorn, an Acorn parser plugin, and Acorn-Walk, which are used to parse and transform any `SpawnExpression` to a regular method call for Babel to recognize in the second stage. `spawn` is a contextual keyword which could also be a regular method call and not a `SpawnExpression`, so the parser looks for any instance of the `spawn` keyword followed by any number of spaces and an identifier character.

The second stage consists of Babel and a Babel transformation plugin which is used to transform all function expressions/statements into GeneratorFunctions, and wrap all functions in detour hooking functions. Within the new GeneratorFunctions all CallExpressions, NewExpressions, ReturnStatements, YieldExpressions, and SpawnExpressions are transformed into yielded instruction tokens. A special token named `loopYield` is added to the beginning of each loop to ensure that they are interruptable.

## Function Detours

The Babel transformation plugin wraps all functions and function calls in detouring functions, and the detour library is a collection of function hooks designed to detour specific types of functions.

- `hookCoroutine` detours a function.
- `hookArrowCoroutine` detours an `ArrowFunctionExpression`.
- `hookGenerator` detours a `GeneratorFunction`.
- `hookIterator` detours an iterator interface object's `next`, `return`, and `throw` methods.

All detours insert a hooking function which replaces the original function with a special invocation adapter. Upon invoking the adapter a new HertzScript virtual machine is started in-place, and the original function is run from within it. The original function is assigned to a Symbol property named `tokenSym`. Each hook marks the detour and original function with special markers symbols which allow the virtual machine to observe information that would originally only be visible at compile-time.

- `tokenSym` is assigned as a property which points to the original function.
- `crtSym` marks a function as a coroutine.
- `conSym` marks a function as a constructor coroutine.
- `genSym` marks a function as a generator.
- `iterSym` marks a function as belonging to an iterator interface object.

## Instruction Tokens

The HertzScript instruction set is a list of "instruction tokens" and is composed of Kernelizer objects, which are generic objects designed to safely wrap user data. Some instruction tokens accept arguments in an array which are assigned to properties in itself via a `set` method. All tokens are gauranteed to only be in-use during 1 cycle because the virtual machine executes in a single thread, and so each instruction token is a single-instance uniqueness type to reduce memory overhead.

All instruction tokens are marked by having a special symbol assigned to them called `kernSym`, and if the virtual machine determines that an object has the symbol as a property then it assumes that the object is an instruction token and attempts to process it.

Instruction tokens are classified by two types:

`loopYield` is a special token which is used to interrupt loops, and does not wrap user datum or invoke any functions.

1. **Invocation Tokens** wrap userland functors and any operands needed to invoke them.

- `call` & `callArgs` invoke a function with and without arguments.
- `callMethod` & `callMethodArgs` invoke a method.
- `new` & `newArgs` invoke a constructor.
- `newMethod` & `newMethodArgs` invoke a constructor from a method.
- `spawn` & `spawnArgs` spawn a new coroutine.
- `spawnMethod` & `spawnMethodArgs` spawn a new corotuine from a method.

2. **Data Tokens** wrap arbitrary userland datum, such as for `return` and `yield`.

- `return` & `returnValue` wraps a `return`.
- `yield` & `yieldValue` wraps a `yield`.

## Virtual Machine

To facilitate the aforementioned instruction stream transformations while preserving normal JavaScript execution, the HertzScript virtual machine implements the behaviors indicated by the instruction set and executes the compiled source code. The virtual machine consumes the instructions which are yielded by the compiled source code, performing the appropriate operations in response to each instruction. The HertzScript virtual machine is written in regular JavaScript which executes within the JavaScript virtual machine.

The HertzScript virtual machine changes how the JavaScript virtual machine call stack is utilized. When a new coroutine is started, a new Coroutine Control Block is created for it which contains a virtual call stack, and the HertzScript instruction set corresponds with operations which push and pop the coroutines in that stack. Only the currently executing coroutine will reside within the JavaScript VM call stack.

The JavaScript VM call stack does not grow past the currently running coroutine except during function calls which were initiated by many of JavaScript's standard operators which are not the invocation operator, loosely limiting the VM call stack to a set length. The end result of this size reduction is that all coroutines are generally able to perform a context switch with `O(1)` time complexity, significantly reducing any possible jitter that would critically impact multitasking operation.

## Dispatcher

The HertzScript dispatcher is a concurrency control system and preemptive multitasking kernel. The dispatcher is responsible for the supervision, scheduling, dispatchment, preemption, and context switching of multiple different HertzScript virtual machines within a single thread.

## Programming Environment

TBD
