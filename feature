
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- Just have an LRU cache under the persistence layer for game.
  That is independent of liveness.
  But you need a list of live game ids for harvesting.

    https://twitter.github.io/util/docs/com/twitter/util/LruMap.html

    Just put that on the backlog for now.

- Make sure adequate tests exist and pass for the service layer with 
  slick json persistence.

