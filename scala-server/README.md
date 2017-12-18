
# Scrabble-Like Board Game

A word game close to scrabble. Not all the scrabble rules are implemented. See
below for known differences.

Drag and drop tiles from the tray to the board to form words, and then click
_Commit Play_ to submit your word. 

You can also drag and drop a tile onto the swap bin, indicating that you are
taking a pass and exchanging one tile. Exactly one tile can be exchanged in a
pass at this time.

After each play or pass, the machine will automatically make its word play.

Please note that although the program's word list is quite large, it is missing
some common English words, which if you happen to play will be rejected. 
This should occur very rarely, however. 

Note also that that plurals and verb conjugations do not generally appear in the 
the program's dictionary and will often be rejected unless of course they are 
menaingful in their own right.

Because the word list is large, you will likely see many strange words
played by the machine. You may wish to install a dictionary browser extension
to be able to see the meaning of such words. 

For example, using Chrome, install the Google Dictionary extension:

https://chrome.google.com/webstore/detail/google-dictionary-by-goog/mgijmajocgfcbeboacabfgobmjgjcoja?hl=en

Then simply click on a word in the game's list view of played words to 
see its meaning (or a link to search the web for it). 

## Known Issues

- No blank tiles.

- No multiple swaps.

- No passes without swapping.

- No parallel plays. 

  A parallel play is a play alongside of a given word which does not
  have an inner anchor point (an already existing connecting tile within the
  played word). Currently the program always expects an inner anchor.

- No end of play score adjustments.

  At end sum up each player's remainig letter values and subtract from that
  player's score. If one player has no letters, the other player's remaining sum
  is also added to the score of the player with no letters

## To Do

- Remove long-running games.

- Clean up and use Moby's: mwords/354984si.ngl 
  Remove words with no-alphabetic characters.
  Credit Moby.  http://icon.shef.ac.uk/Moby/

  Compare with /usr/share/dict/words on Linux.

- Develop integration tests at the level of the handler.
  For all ending conditions.

- Write tests for scoring plays with cross scores.

- Connect to real dictionary. Check with NL experts.

- Document no pass for now. To pass just swap one piece.

- Implement swap taking a possibly empty list of pieces.
  Needs UI swap bin to be a list, plus an explicit pass button.
  UI - if sack is empty, disallow swap.

- New exception for num swapped > sack size. 

- Server. Reject plays after game has been stopped.

- Change logging calls to debug and set up a run-debug to
  log at debug level.

- Test. Two clicks on start button e.g., start in rapid succession??
  On any button? Should be disabled immediately.

- Implement validations everywhere. First on API boundary.

- Clean up tests in web-ui and scala.

- Matching algorithm needs to be based on the best guess as to 
  the real score of a play. Not needed for first release.

- Check that rows.delete deletes everything.

- Test first move being a pass - so next player will have to
  be centered. Check for first move should be be empty board.

- Compute real score in Haskell.

- Document migration and seeding.

- Fully implement GameServiceImpl.

- Do we have to close a db in slick?

- More generic code based on axis - just call generic code on rows or columns 
  depending on axis.

- Change Haskell to conform to new API.

## Technical Debt

- Minimal database interactions. Need to be able to save and restore
  the state of the game. Not all required tables exist. Test with 
  postgres and sqlite.

- API versioning - just include in URL.

- Document seeding and migration.

- PlaySpec has WsClient - how do you use it?

- Production config file has secret and must be read-only to 
  one trusted user.

- Re-enable and configure CSRF filter. See the application.conf for configuration.
  It is disabled there: play.filters.disabled+=play.filters.csrf.CSRFFilter

- Uniqueness of player name. Need an index for the database.

- Need to standardize errors. Including validation of request. Version 2.

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

