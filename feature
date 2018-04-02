
This Feature

For Scala, save the entire game in the database as a single JSON object.
Port to Haskell in a later feature.

- Create a Play data structure. It has two cases: SwapPlay and WordPlay.

- Test encoding and decoding of plays into JSON.

- Add list of plays to the game data structure and maintain it as new plays
  arrive.

- Create a persistence interface for the boardgame.

    addPlayer
    getPlayer
    addGame
    getGame
    updateGame
    closeGame

- Test encoding and decoding of game as JSON.

- Implement the persistence interface for h2.

- Hook up the service layer to the new implementation.

- Make sure adequate tests exist and pass.

- Implement the persistence interface in DynamoDB.


