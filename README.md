# hertzscript-specification

The specification is currently a work-in-progress. For now, here's the high level description!

- [High-Level Synopsis](#high-level-synopsis)
- [Theory of Operation](#theory-of-operation)
	- [Compiler Pipeline](#compiler-pipeline)
	- [Function Detours](#function-detours)
	- [Coroutine Dispatcher](#coroutine-dispatcher)
	- [Instruction Tokens](#instruction-tokens)

A JavaScript source code specification which describes preemptible HertzScript (abbreviated "HzScript") coroutines.

# High-Level Synopsis

The HertzScript system consists of a [Babel](https://babeljs.io/) transformation plugin, an [Acorn](https://github.com/acornjs/acorn) parser plugin, and a coroutine dispatcher with which to execute the resulting source code.

Normally, coroutines are reserved for cooperative multitasking, but HertzScript implements a special type named voluntary preemptive multitasking. In regular cooperative-style programmers must declare points at which programs will yield, and HzScript extends this concept by automating it. Babel is used to transform all source code so that it is able to run concurrently, and Acorn is used to parse a special `spawn` keyword which acts as the primary interface to utilize that concurrency.

The source code HzScript produces can be output in one of two forms:

1. A self-running platform-agnostic JavaScript module which transparently integrates with existing software.

2. A specialized HzModule which can be directly imported into a coroutine dispatcher.

# Theory of Operation

## Compiler Pipeline

HertzScript uses a multi-stage source-to-source compilation pipeline to transform JavaScript functions into instruction streams; all functions within a HzScript program are GeneratorFunctions which yield instructions.

The first stage in the compilation pipeline consists of Acorn, an Acorn parser plugin, and Acorn-Walk, which are used to parse and transform any `SpawnExpression` to a regular method call for Babel to recognize in the second stage. `spawn` is a contextual keyword which could also be a regular method call and not a `SpawnExpression`, so the parser looks for any instance of the `spawn` keyword followed by any number of spaces and an identifier character.

The second stage consists of Babel and a Babel transformation plugin which is used to transform all function expressions/statements into GeneratorFunctions, and wrap all functions in detour hooking functions. Within the new GeneratorFunctions all CallExpressions, NewExpressions, ReturnStatements, YieldExpressions, and SpawnExpressions are transformed into yielded instruction tokens. A special token named `loopYield` is added to the beginning of each loop to ensure that they are interruptable.

## Function Detours

The Babel transformation plugin wraps all functions in detours which are defined in `DetourLib.js`. The detour library is a list of function hooks designed to detour specific types of functions:

- `hookCoroutine` detours a function.
- `hookArrowCoroutine` detours an arrow function.
- `hookGenerator` detours a GeneratorFunction.
- `hookIterator` detours an iterator object's functions `next`, `return`, and `throw`.

All hooks insert a detour which replaces the original function with a special invocation adapter, and upon invoking the adapter a new coroutine dispatcher is started in-place while the original function is run within it. The original function is assigned to a Symbol property named `tokenSym` which is defined in `TokenLib.js`. Each hook marks the detour and original function with special markers symbols which allow the coroutine dispatcher to observe information that would originally only be visible at compile-time. The marker symbols are defined in `TokenLib.js`.

- `tokenSym` is assigned as a property which points to the original function.
- `crtSym` marks a function as a coroutine.
- `conSym` marks a function as a constructor coroutine.
- `genSym` marks a function as a generator.
- `iterSym` marks a function as belonging to an iterator object.

## Coroutine Dispatcher

To facilitate the aforementioned instruction stream transformations while preserving normal JavaScript execution, a coroutine dispatcher which implements the instruction set must be used to execute the compiled source code. Such a dispatcher is defined in `Dispatcher.js` and consumes the instructions which are yielded by the compiled source code, performing the appropriate operations in response to each instruction.

HertzScript's coroutine dispatcher changes how the call stack is utilized in a JavaScript VM. When a new coroutine is started, a new Coroutine Control Block is created for it which contains a virtual call stack, and the HzScript instruction set corresponds with operations which push and pop the coroutines in that stack. Only the currently executing coroutine will reside within the JavaScript VM call stack.

The JavaScript VM call stack does not grow past the currently running coroutine except during function calls which were initiated by many of JavaScript's standard operators which are not the invocation operator, loosely limiting the VM call stack to a set length. The end result of this size reduction is that all coroutines are generally able to perform a context switch with `O(1)` time complexity, significantly reducing any possible jitter that would critically impact multitasking operation.

## Instruction Tokens

The HertzScript instruction set is defined as a namespaced list of "instruction tokens" in `TokenLib.js` and is composed of Kernelizer object instances from `Kernelizer.js`. Each instruction token accepts a custom list of arguments which are assigned to properties in itself via a `set` method. As the coroutine dispatcher executes in a single thread, each instruction token is a uniqueness type to reduce memory overhead.

All instruction tokens are marked by having a special symbol assigned to them called `kernSym` which is defined in `TokenLib.js`, and if the coroutine dispatcher determines that an object has the symbol as a property then it assumes that the object is an instruction token and attempts to process it.

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