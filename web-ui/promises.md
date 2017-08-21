
# Notes on Javascript Promises

## Basic Model

A promise embodies the value of a computation that may become available
at a future time. The promise constructor takes a function parameter,
called the _executor function_ of the promise. The executor function 
computes the future value of the promise - typically asynchronously.
All the data needed to compute that value is obtained from the lexical
context of the call to the promise constructor.

It is, of course, possible for the executor function to fail. But whether the
function succeeds or fails is left at the discretion of the application
programmer. It is the responsibility of the the executor function to distinguish
between success and failure, and to notify the promise framework in each case.
For the purpose of notification of success and failure, the executor function
includes two callback function parameters, one for success and one for failure,
called _resolve_ and _reject_ respectively.

`promise = new Promise(function(resolve, reject) { ... } );`

The resolve function takes a single parameter: the resulting value of the 
computation. The reject function takes a single parameter: the reason for 
the failure of the computation.

The promise contract requires that the executor function call the resolve
function with the result of the computation in case of success, and that it
call the reject function with the reason for failure in case of failure.

I assume that if there is an uncaught exception before either function is
called, the promise is automatically rejected by the framework.

TODO. What if the executor function returns normally without calling 
resolve of reject? What if there is an explicit return with a value.
Or no return?

The implementation of the promise constructor calls the executor function
immediately, supplying it with its own internal resolve and reject callbacks.
We'll call them the _framework resolver_ and the _framework rejector_.

Initially, a promise is in a _pending_ state, meaning its executor is still
computing. When called upon a successful computation, the framework resolver
changes the promise's state to _fulfilled_ and records the computed value.
Similarly, when called upon a failed computation, the framework rejector changes
the promise's state to _rejected_ and records the reason.  A promise is said to
be _completed_ if it is fulfilled or rejected.

## Handling Promise Completion

Each promise keeps track of 2 lists of handlers, resolve handlers, and reject
handlers. The handlers are application-provided. (Not to be confused with the
executor's resolve and reject functions which are provided by the framework.)
The application program can add handlers to a promise's handlers lists using

`promise.then(onFulfilled [, onRejected])` and

`promise.catch(onRejected)`. 

The _then_ and _catch_ functions may be called before or after the promise is
completed. 

When a promise is fulfilled, the handlers in its resolver list are called with
the promise's value. When a promise is rejected, the handlers in its
rejector list are called with the promise's reason for failure. In addition,
whenever a new resolve handler is added to the list after the promise is
fulfilled, that handler is schduled for execution with the value of the promise.
Similarly, whenever a new reject handler is added to the list after the
promise is rejected, that handler is scheduled for execution with the reason for
the promise.

The 'then' and 'catch' functions add their handlers to the appropriate list(s), and
return another promise. That promise's eventual state is determined by what
happens in the handler when called. The handler may return an explicitly
resolved or rejected promise by using _Promise.resolve()_ and
_Promise.reject()_ (see below). Or it may return a non-promise value, which, I am guessing,
is wrapped in a resolved promise (TODO check). If there is an uncaught exception
in the handler's execution, that exception is turned into a rejection by the
framework.

Note that the return type of the onFulfilled callback is conflated: it can be a
promise, or it can be a value. If it is a value (not a promise) that value is
wrapped in a fulfilled promise by the framework. Similarly for onRejected.

Note that if a catch handler returns normally, the returned promise from the
catch handler becomes fulfilled (i.e., resolved). The only way that the promise
returned from a catch becomes rejected is if the catch handler explicitly
returns a _Promise.reject_, or if there is an iuncaught exception in the catch
handler.

## Further Details

- `Promise.resolve(value)` - returns a promise resolved to the given value.

- `Promise.reject(reason)` - returns a rejected promise.

Generally an asynchronous operation has callback methods for success and failure. 
To _promisify_ such an asynchronous operation, make a promise with an executor
function that calls resolve in its success callback and calls reject in its
failure callback.

For example, the xhr object returned by by XMLHttpRequest has callback methods
called _onload_ and _onerror_ for success and failure respectively. To promisify
the operation, a promise is created that calls resolve in the onload method, and
calls reject in the onerror method.

In case you find an error in a then, you can just return a new rejected promise,
by creating it like this: return Promise.reject(yourReason).

At the highest level, for cleanliness, one should make sure that the catch
handler is real simple, deals with all errors, does not cause exceptions, and
does not return a rejected promise.

At lower levels certain rejections may have to be translated to rejections
that higher levels are prepared to deal with - just like with exception 
translation.

## A Transactional Pattern for Multi-Promise Operations

One common scenario when using promises is when multiple calls to an api that
returns promises are chained in completing some higher level operation. 

The way I have chosen to deal with this scenario in simple cases is to use lower
level calls that are transactional in their 'then' processing. If any issue is
discovered or are encountered in the 'then' function, the state of the world is
restored to its original values. Then the then function returns a resolved
promise that indicates the failure of the call. 

Later thens in the chain check for the failure in their then processing and in
case of failure simply pass along the promise (they skip normal processing).

The lower level functions do not catch rejections. That way, the higher level
chain can catch all rejections in one place. That is often sufficient as
rejections are generally catastrophic and a aborting the entire operation can
often be coded generically. Also, not processing rejections in the lower levels
means that higher level thens in the chain are simply skipped. Otherwise, a
lower-level catch can translate a rejected promise into a resolved one and later
thens in the chain may not know any better (unless the code if surther
complicated, that is).

## Testing with Promises

See https://facebook.github.io/jest/docs/asynchronous.html.

## References

https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise

https://developers.google.com/web/fundamentals/getting-started/primers/promises

http://2ality.com/2016/03/promise-rejections-vs-exceptions.html

https://stackoverflow.com/questions/33445415/javascript-promises-reject-vs-throw

http://www.datchley.name/es6-promises/

http://www.datchley.name/promise-patterns-anti-patterns/
