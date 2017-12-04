
- Web UI needs to send StartGameRequest.

- integration test

  console.log src/__integration.tests__/client.api.test.js:33
    {"obj":[{"msg":["error.expected.jsobject"],"args":[]}]}

  The API is defined to send an array - but it needs an object.

  [{"height":5,"width":5,"trayCapacity":3,"languageCode":"","playerName":"You","pieceGeneratorType":"cyclic"},[],[{"value":"B","id":"1"},{"value":"E","id":"2"},{"value":"T","id":"3"}],[{"value":"S","id":"4"},{"value":"T","id":"5"},{"value":"Z","id":"6"}]]


- How to give http.port to sbt?

- How to gve http.port to intellij. In Play2Run configuration add
  -Dhttp.port=6587. Worked.

# Latest TODO

- Run integration test against scala application.

- Add the bundle and get it to work.

- Get CORS for development to work.

- TODO. Need a view for the page?

- Change web ui accordingly.

- Test web ui with scala server.

- TODO. Check that rows.delete deletes everything.

- PlaySpec has WsClient - how do you use it?

- Run application and make sure it comes up.

- Document seeding and migration.

- TODO. Production config file has secret and must be read-only to 
  one trusted user.

- I think you have to put the bundle into public/javascripts. And have a GET for it.

- TODO. Need to standardize errors. Including validation of request. Version 2.

- To connect to javascript:
  https://github.com/nouhoum/play-react-webpack/blob/master/app/views/index.scala.html
  I am not sure this is needed. But keep until the whole thing works.

- public/javascripts/main.js - add in the bundle

- Create an application test.

- Added explicit allow origin to javascript client api. 
  Remove if it does not work.

- corsHeaders is a list of headers

- TODO. CORS.

- Tests should use small data structures so the data is controllable.

- turning off/on persistent logging selectively just for persistence
  using control.monad.log - logging effects

- check logs on oceanpark

- export `GAME_SERVER_URL="http://localhost:6587"` no slash at the end

## To Do

- Haskell - GameParams add pieceGeneratorName. And test - integration and
  manual.

- Haskell - index too large error is still intermittent - added debugging prints hoping
  to discover where it happens. Remove prints.

- Change the secret key to a real secret for production. Read the documentation.

- Bug extending a word should work constitute a legitimate play.

- For now user goes first. TODO. After starting a game, toss a coin in the client 
  to determine who goes first. If it is machine, do a machine play.

  Add center square image.

- Uniqueness of player name. Need an index for the database.

- Add api versioning to todo list. just add it to the beginning of the url.

- Check strip is free crosswise.

- Do we have to close a db in slick?

- Add static content. This shows how to get static content. It is a good example to emulate for
  converting as well. You probably want to use getFromDirectory.
  
  https://doc.akka.io/docs/akka-http/current/scala/http/routing-dsl/index.html#configuring-server-side-https

  The implicit protocol can be json in which case marshalling/unmarshalling
  is json.

  Testing: http://blog.madhukaraphatak.com/akka-http-testing/
          https://doc.akka.io/docs/akka-http/current/scala/http/routing-dsl/testkit.html

  https://medium.com/dive-in-scala/building-rest-api-web-service-using-akka-http-showing-crud-operations-baked-with-redis-d15f4c4bf4d5

## Improvements

- Removing abandoned games. Does it make sense to use Akka?

- Seeding should be part of migration.

  The program should know its own version. The database should know which
  version it is at. There is an ordered list of upgrade functions
  for each version. All we need is that the version numbers be ordered.
  Lexicographic order on the parts of the version.

  You run those upgrades that are for versions greater than the database
  and less than the program. If the data database is at a higher version
  should not run the program.

- Creare a scala branch and move the code over. Add license headers.
  README - work in progress.

- More specific match tests and assertions. Later.

- Use the convention of no parens if there are no side effects 
  for no-arg functions.

- Add tests similar to the ones in the sample, then remove the sample.

- Change the board to look like a scrabble board.

- Change the scoring to be consistent with scrabble.

- Change the probabilities to be consistent with scrabble.

- Connect to real dictionary.

- Read your for comprehension writeup and tutorial.

- Describe how the route dsl actually works - what are the methods,
  and what are implicit parameters and where do they come from.

- Understand and document basic slick model of actions.

- Add end paths and tests for extraneous path elements.

- Database migration. Later.

- Add play table.

- tray - find a word without constraints based on tray - that is 
  the initial play by the machine. Randomly choose who plays first.

  Initial word by player is also unconstrained - except it has to be 
  cover the center.

- config db should give the default dev test and prod databases
  todo - later - best practices for config - reference vs application

- Add end path to all legitimate paths so exclude extraneous trailing path segments.

- Parallel execution of tests. Later.

- Better API structure - all calls should return: Either[GameError, Result].
  But needs to be done in Servant as well.

- What to do with fatal exception in a web server? 
  Need to research for later. For now let the framework handle it.
  Also if any regular exception escapes the Try just let the framework handle
  it for simplicity.

- Should the end point layer call on services asynchronously? Is there a
  special way of doing that in Akka Http?

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

