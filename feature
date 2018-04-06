
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- Done. Can serialize and deserialize GameTransitions.

- Game.toGameTransitions trivial.

- In tests and in server impl change state to game, and game
  to gameInitialState.

- Add endGame to Game. It was removed from GameInitialState.
  The only way we know that a game has ended.

- Add implementation version to json.

- Remove lastPlayScore.

- Clean up the code so far - ready for new storage layer.

- Create a storage layer for boardgame. Refactor the game cache to 
  the implementation of this interface. The implementation calls the 
  persistence layer if the game is not in the cache.

- Create a high-level persistence layer for the boardgame. It works with 
  entire games as Scala data structures.

    addPlayer
    getPlayer
    addGame
    getGame
    updateGame
    closeGame

- How about giving the game the dictionary?

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

