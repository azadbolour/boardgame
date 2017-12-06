
- Removing height and width from scala.

- Remove from UI.

- Remove from Haskell.


- SBT compilation for play2 is disabled by default.

- The intellij play configuration is messed up and I am wasting
  too much time trying to make it right. 

- Right click project, Add Framework Support in intellij to 
  add Play support to a project.

- Cannot run tests from intellij - either can't find the test
  or module is not specified. Delete the run configuration.
  Still can't find the class. Invalidated caches and restarted 
  and still getting the same problem.

  There is a warning about JavaLaunchHelper being available
  from two different places. Not sure if that is the cause 
  of the problem. Suggested fix for the latter is to upgrade 
  to:

      oracle jdk 8u152

- Let's do that and hope it solves the issue.

- Eliminate height and width grid constructor parameters.

- Write test for dimension 15 board multiplier and make sure
  all points in the first octant are covered.

- Make sure dimension is odd.

- Add letter scores to pieces.

- First in Scala - then in javascript.

- For simplicity - just add the number after the letter for now.
  Did not figure out a good way of changing font size within text.

- Prototype adding score factors in React. Just absolute with some 
  offset.

- Add double triple letter and word indicators to board.
  For now indicate 2L, 3L, 2W, 3W on one corner.

  center - star - pink
  corner - 3W - red
  edge middles - 3W - red
  edge quarters - 2L - light blue
  diagonal offset 1 from center - 2L light-blue
  diagonal offset 2 from center - 3L blue
  diagonal - not corner - 2 or more away from center - double word - pink
  quarter diagonal - offset 1 from edge - 3L blue
  quarter diagonal - offset > 1 from edge <= 1/4 from edge - 2L light blue

- Add value of piece to piece image. Can you use subscript
  with smaller font?

    Blank Tiles = 0 points
    A – E – I – O – - U – L – N – R – S – T = 1 point
    D – G = 2 points
    B – C – M – P = 3 points
    F – H – W – Y – V = 4 points
    K = 5 points
    J – X = 8 points
    Q – Z = 10 points

- TODO. Rule for ending the game is part of refactoring to use bag of letters
  without replacement.

## To Do

- Intellij - add license header for file creation.
  Add license to recent new files.

- Check that rows.delete deletes everything.

- Do we have to close a db in slick?

- Add tests similar to the ones in the sample, then remove the sample.

## Known Issues

- No checks for crosswise words yet.

- For now user goes first. After starting a game, toss a coin in the client 
  to determine who goes first. If it is machine, do a machine play.

  Add center square image.

- Bug extending a word should constitute a legitimate play.

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

- Change the board to look like a scrabble board.

- Change the scoring to be consistent with scrabble.

- Change the probabilities to be consistent with scrabble.

- Connect to real dictionary.

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

- Add bonus points and use the same tile values and Scrabble.

- Allow game to be resumed.

- Indexing.

- Provide levels in game.

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

