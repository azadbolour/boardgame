
# Design Patterns

Work in progress.

## Game Cache

The cache is map of gameId (string) to game and includes all 
currently-running games. For simplicity, we just restrict the 
total number of games that can be active at any given time to a
configuration variable maxActiveGames.

When the cache is full, the start API call will receive a 
SystemOverloaded error.

To deal with abandoned game we use the simple strategy of 
limiting the duration of all games. The corresponding 
configuration variable is maxGameMinutes. A daemon thread
called the _harvester_ removes timed-out games from the cache
on a regular basis.

The cache is accessed by multiple threads servicing different
user connections, and also by the harvester thread.

We use a separate MVar lock to synchronize access to the cache.

For most operations we can first read the cache safely by using readMVar. Then
extract what we need from ut and act on that producing the data that is needed
to update the cache on the side. Then use a _bracket_ transaction to acquire the
lock with takeMVar, get the latest version of the cache, do the update, and
release the lock by putMVar. Splitting the initial read from the final update
transaction is generally possible as long as the update operation is aware that
some games existing in the original read may have ended and no longer be present
in the cache.

