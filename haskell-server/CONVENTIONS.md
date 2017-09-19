
# Hasell Coding Conventions

## Type and Constructor Naming

Types and constructor names are generally chosen not to clash with 
library types and constructors, and with other types and constructors
in the project. That way they can be imported and referred to uniquely without
the need for a qualifying prefix.

import BoardGame.Server.Domain..Game (Game, Game(Game))

Other than this special case, import everything else qualified so that 
references to symbols will always be prefixed by the qualified names and
be unambiguous.

If some qualified function appears many times in a module, and there is 
little chance of conflict, to reduce bulk, that function may be imported
unqualified as an exception. 

## Name Clash Avoidance

Do use the following extenstions:

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}

### Imports 

It is highly advisable to explicitly list the imported members of a module in 
the import statement. That way it is easy to see where a name used in the
code comes from. 

For all other symbols, always import qualified and prefix the symbol by the
qualified alias.

The qualification name should be the same as the base module name,
unless there is a clash, or some other good reason to change it. Abbreviated names
often make the code harder to read. Try to avoid them.

A simple way to avoid name clashes for fields is not to use them as functions
but instead extract them by pattern matching:

  `
  {-# LANGUAGE NamedFieldPuns #-}
  {-# LANGUAGE DisambiguateRecordFields #-}
  {-# LANGUAGE RecordWildCards #-}

  (game @ Game {gameId, dictionary, board, trays}) = ....
  `

### Import Blocks

Use separate blocks for imports from libraries and imports from the project.
Group imports by package name. Separated by blank lines.

## Comment do Blocks

Unless the monadic type of a do block is explicitly provided in the immediate context,
comment a do block with the monad it is operating under.

do -- IO
  x <- getSomething
  ....

## Line Length

Up to 100 or so is OK. 80 or less is preferable. Readability overrules.

## Functions

Few (<= 7) lines preferable. To enhance readability, avoid abbreviations in 
names to the extent practical (except for well-established abbreviations 
in the English language or in general software practice).

## Exceptions

Do not use exceptions in application code. But exceptions may arise
from runtime issues in application code not uncovered by tests, 
and possibly from lower level libraries. Therefore, we catch 
all exceptions when we run the game transformer stack, and 
convert them to internal errors which are then treated normally
as ExceptT within the game transformer stack. Note that generally
exceptions may be caught only in the IO monad. However, we need
to catch them in the game transformer stack.

For details of catching exceptions and catching them in particulat 
in monad transformer stacks, see the following:

http://chimera.labs.oreilly.com/books/1230000000929/ch08.html#sec_exceptions

https://www.schoolofhaskell.com/user/snoyberg/general-haskell/exceptions/catching-all-exceptions

https://hackage.haskell.org/package/enclosed-exceptions-1.0.2/docs/Control-Exception-Enclosed.html

See GameTransformerStack.hs for the code to catch and convert exceptions
in the game transformer stack.

Note that to make sure all exceptions are caught in general we need to use the
function catchAnyDeep which forces the evaluation of the result of game
transformer stack operations. In order to force evaluation, catchAnyDeep needs
the results of operations to be strictly evaluable, which is done by making the
result of all operations instance of NFData. Thus, catching all exceptions,
unfortunately, implies polluting much of the code with 'deriving NFData'.

Note also the catchAnyDeep will not catch asynchronous exceptions,
that is, signals from other threads to the current thread. That is
the way it should be, as we do want kill signals to be recieved by the
thread.

## References

- The book 'Parallel and Concurrent Programming in Haskell' by
  Simon Marlow is an excellent resource.  
  
  http://chimera.labs.oreilly.com/books/1230000000929

## Notworthy

- Async is haskell's answer to futures. But note that 
  its synchronization model is wakeup all on resolution. This may
  or may not be what is required. For our application, we found it
  simpler to ensure synchronization by using the single wakeup 
  model, and implement that directly using MVars.

  See:

  https://hackage.haskell.org/package/async-2.1.1.1/docs/Control-Concurrent-Async.html

  See also Parallel and Concurrent Programming in Haskell.

## Haskell Notes and Reminders

- Remembering how sections are interpreted:

  Examples: 
  
      `(: [])` - cons with the empty list
      `(x <)` - true for values greater than x

  In the resulting one-argument function, the argument is placed 
  in the slot of the missing place holder and the expression in evaluated:

  `(arg : [])` and `(x < arg)`

## Persistence

Treat Persistence (upper-case 'P') row ids as the private fields of the
representation of objects in the database. They are used to related records in
the database.  Higher levels of the application should have their own
application-level unique ids for set of objects. Higher level code should be be
dependent on the implementation details of persistence (lower-case 'p').
