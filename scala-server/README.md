
## Production Considerations

- For secure encryption, the play application requires a secret key, as the 
  value of the configuration parameter `play.http.secret.key`. 

    http://playframework.com/documentation/latest/ApplicationSecret

  In a production environment, secrets will be securely stored in an
  external vault and securely communicated to the application. 
  The retrieval of secure parameters is abstracted out in the script
  `get-dynamic-params.sh`. The wrapper script, `run-server.sh`, used 
  to start the application gets the dynamic parameters through this
  script, and provides them to the server via system properties.

  The script `get-dynamic-parameters.sh` needs to be customized to 
  access the secure vault provided by each specific deployment 
  environment. This remains a manual step for now. TODO. Automate
  the provision of different implementations for for
  `get-dynamic-parameters.sh`.

- The play application uses a lock file while it is up.
  After a crash, the lock file stays put and prevents a restart.
  In order to be able to easily remove the lock file, it is [by default]
  externalized to the host directory `/var/run/boardgame`. The scripts
  create the directory of the pid file on the host system. But they expect
  to be permitted to do so.

## To Do

- Use persistent database. Currently using h2.

- Gracefull rejection of plays after game has stopped.

- Change logging calls to debug and set up a run-debug to
  log at debug level.

- Implement validations everywhere. 

- Do we have to close a db in slick?

## Technical Debt

- Minimal database interactions. Need to be able to save and restore
  the state of the game. Not all required tables exist. Test with 
  postgres and sqlite.

- API versioning - just include in URL.

- Streamline and document seeding and migration. Use Liquibase-type migration.

- Store and retrieve the play _secret_ securely in the production deployment.

- Re-enable and configure CSRF filter. See the application.conf for configuration.
  It is disabled there: play.filters.disabled+=play.filters.csrf.CSRFFilter

- Uniqueness of player name. Need an index for the database.

- Standardize errors in the API itself - so that different server implementations
  would look the same to the client in case of errors. Include validation of requests.

- Document basic Slick model of actions.

- Parallel execution of tests. 

## Improvements

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

