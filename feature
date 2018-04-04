
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- Change PlayerType from enum to sealed abstract.

- Change name GameJsonSupport to GameApiJsonSupport.

- Add new file JsonConverters in the service layer for now.
  Move all the spray stuff there.

- Test encoding and decoding of plays into JSON. spray-json looks simple
  enough for case classes. Keep this layer independent of Play.

  https://github.com/spray/spray-json

  Understand encoding of an abstract class with multiple cases to JSON.

  The simplest solution so far seems to be to just add a tag field to
  the base class that represents the case.

  https://stackoverflow.com/questions/20946701/how-to-serialize-case-classes-with-traits-with-jsonspray

  Not sure how a simple enumerated data type (with sealed abstract class and
  case classes) is serialized and deserialized.

  Create a test for serialization.

  Remommend against suing scala enumeratrion infavor of sealed abstract class
  with type classes for the different cases.

- There is probably no good reason to separate game and game reason any more.
  Check it out and if so, combine, since the persistence layer deals
  with entire games.

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

  We'll need a join to get games of a particular user. Best practices for joins
  in DynamoDB.

- Design the schema for DynamoDB.

- Downlaod DynamoDB local and understand how to interact with it from the 
  command line.

  https://aws.amazon.com/blogs/aws/dynamodb-local-for-desktop-development/

- Implement and test the low-level persistence interface in DynamoDB local.

