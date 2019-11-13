# HertzScript Systems Specification

This specification describes the requirements and business logic of the HertzScript coroutine systems.

[Click here to view the specification.](http://hzscript.io/dist/Specification.html)

# Reference Systems & Supporting Technologies

- [HertzScript Compiler](https://github.com/hertzscript/Compiler)
	- [Babel](https://babeljs.io/)
	- [Acorn](https://github.com/acornjs/acorn)
	- [marktail](https://github.com/Floofies/marktail)
- [HertzScript Virtual Machine](https://github.com/hertzscript/VirtualMachine)
- [HertzScript Multitasking Dispatcher](https://github.com/hertzscript/Dispatcher)
- [HertzScript Multiprocessing Isolate](https://github.com/hertzscript/Isolate)
- [HertzScript Programming Environment](https://github.com/hertzscript/Environment)

# Project Objective

Abstracting the event loop is a must for developers who are creating and maintaining large JavaScript systems, but the existing JavaScript multitasking systems require far too much developer involvement.

In regular JavaScript the results of blocking the event loop can sometimes be catastrophic, both to the end-user experience and program performance. To solve the problem it is neccesary to split up segments of source code in order to concurrently execute them in the event loop; this solution has several drawbacks if implemented manually by the developer. With traditional JavaScript concurrency the developer often becomes highly involved in the implementation details of such concurrent execution. Developers may be required to manually split apart their source code, prepare and submit it to the event loop, track state data, manage communication between functions, prevent race conditions, and sometimes track the reentrancy of functions. All of these drawbacks increase technical debt and complexity, introduce bugs, obfuscate control flow, delay timers, reduce source code readability, and reduce maintainability.

HertzScript implements JavaScript [Green threads](https://en.wikipedia.org/wiki/Green_threads) by automatically transforming all functions into preemptible coroutines, and has the ability to pause any JavaScript function while it is executing. New coroutines are started whenever a function has been submitted to the event loop, and developers may also start coroutines via a new optional `spawn` keyword. HertzScript takes over all multitasking responsibilities, and allows developers to reliably multitask between several functions without touching any the implementation details. HertzScript periodically preempts functions and allows the event loop to run; long-running CPU-bound functions no longer have to be split apart, and can remain entirely intact without blocking the event loop for too long.