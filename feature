
This Feature

Save the entire game in the database as a single JSON object (Scala).
Port to Haskell in a later feature.

- There is probably no good reason to separate game and game state any more.
  Check it out and if so, combine, since the persistence layer deals
  with entire games.

- Done. Rename Game to GameInitialState.
  Add initial board and trays it.

- Done. Rename GameState to Game.
  
  addPlay does the following

          (newState, refills) <- state.addPlay(MachinePlayer, playPieces, updateDeadPoints(od.get))
          (newBoard, deadPoints) = updateDeadPoints(od.get)(newState.board)
          finalState = newState.copy(board = newBoard)

- state.swapPice - should become addSwapPlay
  It should also add to the playeffect

  addPlay should become addWordPlay

- Change Game addPlay to just use Play.
  Compute play in GameServiceImpl and pass.

- The change in the board includes making the play, and possibly 
  certain other changes. 

  state.addPlayEffect(board, playEffect)- will add it to the list


- Change all names from state to game in GameServiceImpl.


- Add implementation version to json.

- Add initial state variable to GameInitialState.

- Make addPlay just take a Play. 

  Add a parameter deadPointDetector a function that returns dead points.
  Then you can just do all the changes in addPlay and add the play effect to 
  the list as well.

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

