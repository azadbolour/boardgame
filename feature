
This Feature

For Scala, save the entire game in the database as a single JSON object.
Port to Haskell in a later feature.

- Create a Play data structure. It has two cases: SwapPlay and WordPlay.

- Test encoding and decoding of plays into JSON.

- Add list of plays to the game data structure and maintain it as new plays
  arrive.

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

- Test encoding and decoding of game as JSON.

- Create a low-level persistence interface for boardgame. It works
  with entire games as JSON.

- Implement the low-level persistence interface in h2.

- Hook up the service layer to the new storage implementation.

- Make sure adequate tests exist and pass.

- Understand the DynamoDB high level SDK model for Java. 
  Use the java interface directly to have full control and visibility
  into the DynamoDB facilities.

  https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.html

- Downlaod DynamoDB local and understand how to interact with it from the 
  command line.

  https://aws.amazon.com/blogs/aws/dynamodb-local-for-desktop-development/

- Implement and test the low-level persistence interface in DynamoDB local.

