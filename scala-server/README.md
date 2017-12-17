
- Game component - add pass functionality. 
  Change all END to PASS.

- Implement pass - swap takes list.

- Test with small boards to reach end of game.

- Internal handlers will return data needed by the top-level handlers
  in a promise. 

  Then add endInternal and call it. Remove end button.

- handleGameInternal - render game summary.
  add miniState to aux game data??

  After each call update the miniState.

- If noMorePlays call end API and end game.

- Report sack size or empty in UI.

- UI check for noMorePlays and disable all plays. 
  Report end of game.
  And call game end to get summary and show summary.

- UI - button for pass.

- UI - if sack is empty, disallow swap.

- UI - make sure trays with less contents than capacity are handled properly.

- Replacements for a play are the min of used pieces and sack length.

- Write tests for scoring plays with cross scores.

- Connect to real dictionary. Check with NL experts.

## To Do

- Harvest long-running games.

- Server. Reject plays after game has been stopped.

- New exception for num swapped > sack size. 

- Change various logging calls to debug and set up a run-debug to
  log at debug level.

- Swap API - use List. 

- Integration test. First play is a machine play and it is a pass. 
  Both client and server should do the right thing. Client has
  to make sure user move is centered.

- Test. Two clicks on start button e.g., start in rapid succession??
  On any button? Should be disabled immediately.

- Document. Test assertion exceptions are converted to Failure 
  in Try for blocks. So they do not cause test failure automatically.

- Implement validations everywhere. First on API boundary.

- Clean up tests in web-ui and scala.

- Implement random w/o replacement piece generator.
  numLetterInBag(ch) = min(1, round(frequency(ch) * dim * dim / (15 * 15))

  exchanges go back in the bag

- Matching algorithm needs to be based on the best guess as to 
  the real score of a play. Not needed for first release.

- Check that rows.delete deletes everything.

- Test first move being a pass - so next player will have to
  be centered. Check for first move should be be empty board.

- Compute real score in Haskell.

- Document migraion and seeding.

- Fully implement GameServiceImpl.

- Do we have to close a db in slick?

- Add tests similar to the ones in the sample, then remove the sample.

- More generic code based on axis - just call generic code on rows or columns 
  depending on axis.

- Change Haskell to conform to new API.

## Known Issues

- Game end rules are ignored - the user ends the game. 

  The ending rules are:

    game ends when all letters have been drawn and
    both players pass

    or when six consecutive non-board plays have been made

    at end sum up each player's remainig letter values
    and subtract from that player's score

    if one player has no letters, the other player's
    remaining sum is also added to the score of the 
    player with no letters

    so we need a model of drawing letters without replacement
    (except in exchanges)

    for initial simplicity we'll just code the 6 consecutive
    non-board plays - or when 100 have been placed on the 
    board - let us say (dimension * 2/3) squared tiles

- No parallel plays. A parallel play is parallel to and adjacent to a 
  a given word with all crosswords existing in the dictionary
  in this case, no anchor is needed. We can ignore this initially
  for machine plays. But it is for now also disalloed for user plays.

- Only single tile replacements allowed. And no passes without exchanges.

- Using random tile selection *with replacement*. Bag model requires random
  tile selection without replacement (except for swap which replace one 
  tile with another).

- Game is ended by the user. Not following the normal rules for ending the game.
  Rule for ending the game is part of refactoring to use bag of letters
  without replacement.

- Minimal database interactions. Need to be able to save and restore
  the state of the game. Not all required tables exist. Test with 
  postgres and sqlite.

- No blank tiles.

- No checks for crosswise words yet.

- Allow an existing word to be extended. 
  Bug reported with Haskell.
  Can't reproduce in Scala.

## Technical Debt

- API versioning - just include in URL.

- Document seeding and migration.

- PlaySpec has WsClient - how do you use it?

- Production config file has secret and must be read-only to 
  one trusted user.

- Re-enable and configure CSRF filter. See the application.conf for configuration.
  It is disabled there: play.filters.disabled+=play.filters.csrf.CSRFFilter

- Uniqueness of player name. Need an index for the database.

- Need to standardize errors. Including validation of request. Version 2.

- Removing abandoned games. Does it make sense to use Akka?

- Database migration. 

## Improvements

- Seeding should be part of migration.

  The program should know its own version. The database should know which
  version it is at. There is an ordered list of upgrade functions
  for each version. All we need is that the version numbers be ordered.
  Lexicographic order on the parts of the version.

  You run those upgrades that are for versions greater than the database
  and less than the program. If the data database is at a higher version
  should not run the program.

- More specific match tests and assertions. 

- Document basic slick model of actions.

- Add play table.

- config db should give the default dev test and prod databases
  todo - later - best practices for config - reference vs application

- Parallel execution of tests. Later.

- What to do with fatal exception in a web server? 
  Need to research for later. For now let the framework handle it.
  Also if any regular exception escapes the Try just let the framework handle
  it for simplicity.

- Should the controller call on services asynchronously? 

- https://github.com/adambom/dictionary. It is 1913 Webster Unabridged. 
  Does not have transistor, software. Abandoned it. Although we can still use it
  for the machine. It has a simple json list of word + meaning.

  Other resources are also based on the 1913. So for machine plays that might be
  good enough.

  Best to ask Natural Language experts.

- Linux dictionary:

    http://www.dict.org/bin/Dict - you can send a post request to this
      I guess you can start by just using this. 
      You can run your own server if the game becomes popular.
      Just view the source for this and use an http client to get it.

    http://www.dict.org/links.html

      Has links to client server software.

    http://www.informatik.uni-leipzig.de/~duc/Java/JDictd/
      provides an http server - it is old though 2004
    https://askubuntu.com/questions/650264/best-offline-dictionary-for-14-04-lts
    http://manpages.ubuntu.com/manpages/zesty/man8/dictd.8.html
    https://github.com/rocio/dictd/blob/master/src/test/java/com/dictionary/service/DictdTest.java

- Load balancing and monitoring crashes and restarting.

- Add real dictionary with meanings. There is a dictionary application built-in 
  to MAC. Is it on Linux? Should be able to get to it easily from Scala.

- Allow game to be resumed.

- Indexing.

- Implement sqlite file based access. May need a little experimentation.

      jdbc:sqlite:/home/me/my-db-file.sqlite
      val db = Database.forUrl("url",driver = "org.SQLite.Driver")

    slick.dbs.default.driver="slick.driver.SQLiteDriver$"
    slick.dbs.default.db.driver="org.sqlite.JDBC"
    slick.dbs.default.db.url="jdbc:sqlite:lite.db"
    slick.dbs.default.db.user="sa"
    slick.dbs.default.db.password=""
    slick.dbs.default.db.connectionInitSql="PRAGMA foreign_keys = ON"

    db {
        test {
            slick.driver = scala.slick.driver.SQLiteDriver
            driver = org.sqlite.JDBC
            url = "jdbc:sqlite::memory:?cache=shared"
           connectionPool = disabled
       }
    }

## Credits

Test Dictionary - http://www-personal.umich.edu/~jlawler/wordlist.html
compiled by John Lawler and put in the public domain with no restrictions
of use.

