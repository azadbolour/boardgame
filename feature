
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- Implement mock json persister.

- Remove the DAO and replace with persister layer.
- Why not have dictionary as part of the current state of the game?

- Just have an LRU cache under the persistence layer for game.
  That is independent of liveness.
  But you need a list of live game ids for harvesting.

    https://twitter.github.io/util/docs/com/twitter/util/LruMap.html

    Just put that on the backlog for now.

- Create a storage layer for boardgame. Refactor the game cache to 
  the implementation of this interface. The implementation calls the 
  persistence layer if the game is not in the cache.

- Create a high-level persistence layer for the boardgame. It works with 
  entire games as Scala data structures.

- Computing blank points recursively should go to strip matcher.
  Or the other way around.

- Create a low-level persistence interface for boardgame. It works
  with entire games as JSON.

- Implement the low-level persistence interface in using Slick and h2.

- Hook up the service layer to the new storage implementation.

- Make sure adequate tests exist and pass.

- Understand the DynamoDB high level SDK model for Java. 
  Use the java interface directly to have full control and visibility
  into the DynamoDB facilities.

  https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.html

  We'll need a join to get games of a particular user. Best practices for joins
  in DynamoDB.

- Design the schema for DynamoDB.

- Downlaod DynamoDB local and understand how to interact with it from the 
  command line.

  https://aws.amazon.com/blogs/aws/dynamodb-local-for-desktop-development/

- Implement and test the low-level persistence interface in DynamoDB local.

