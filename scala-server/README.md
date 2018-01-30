
## To Do

- Use persistent database. Currently using h2.

- Gracefull rejection of plays after game has stopped.

- Change logging calls to debug and set up a run-debug to
  log at debug level.

- Play should be disabled while earlier play is in progress.

- Implement validations everywhere. 

- Do we have to close a db in slick?

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

- Use Liquibase-type migration.

- Document basic slick model of actions.

- Parallel execution of tests. 

## Improvements

- Add play table for Scala.

- Should the controller call on services asynchronously? 

- Load balancing and monitoring crashes and restarting.

- Allow game to be resumed.

- Scala. Implement sqlite file based access. May need a little experimentation.

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

