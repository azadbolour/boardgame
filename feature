
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- There is probably no good reason to separate game and game state any more.
  Check it out and if so, combine, since the persistence layer deals
  with entire games.

- Rename Game to GameInitialState.
  Add initial board and trays it.

- Rename GameState to Game.

- Make addPlay just take a Play. 

- Add a list of plays to Game and if the play is validated,
  augment the list. Make it a vector. Ordered im time, play goes
  to the end.

- Remove endTime and lastPlayScore.

- Implement game recovery from initial state and plays.

  def recoverGame(InitialGameState, List[Play]): Game 
    computes the running game state fields and constructs game.

  Test that game is recovered correctly.

- Add json encoding and decoding for game. Test.

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

