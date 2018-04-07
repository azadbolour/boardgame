
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- Coded slick json implementation. 

- For now just delete games when they are completed or harvested.

- Just have an LRU cache under the persistence layer for game.
  That is independent of liveness.
  But you need a list of live game ids for harvesting.

    https://twitter.github.io/util/docs/com/twitter/util/LruMap.html

    Just put that on the backlog for now.

- Create a storage layer for boardgame. Refactor the game cache to 
  the implementation of this interface. The implementation calls the 
  persistence layer if the game is not in the cache.

- Computing blank points recursively should go to strip matcher.
  Or the other way around.

- Remove GameDaoMock and GameDao and GameDaoSlick.

- Hook up the service layer to the new storage implementation.
  Check hookup in master.

- Make sure adequate tests exist and pass.

