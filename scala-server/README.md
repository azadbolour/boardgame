
## Setting up the Host Deployment Machine

- Before you can deploy the docker container on a host machine,
  a couple of preparation steps are needed on that machine.
  This is a one-time setup that is largely scripted in the script
  `prod-initial-setup.sh`. You need to run this script on the host 
  machine, and then edit the externalized Play configuration file
  that it creates to add in deployment-time configuration parameters.
  See below for details.

- For security reasons, the Play framework requires the hostname:port
  information of the hosts that can use the application to be provided 
  in the application configuration file via the configuration parameter
  `play.filters.hosts` like this:

    `
    play.filters.hosts {
      allowed = ["host1.com:8080", "host2.com:8090]
    }
    `

  However, this information is only available at deployment time. Because 
  the application is deployed in a docker container, the hosts information
  has to be provided to the docker container externally at deployment time.

  By convention, the deployment scripts expect an external configuration file 
  to be provided on the host machine where the docker image is being installed
  at the following location:

      `/opt/data/boardgame/conf/prod.conf`

  This file can refer to the packaged `application.conf` file for all built-in
  configurations, but provide the deployment configuration options. It would 
  look something like:

    `
    include "application"

    play.filters.hosts {
      allowed = ["thehost:8080"]
    }
    `

- For secure encryption, the play application requires a secret key, as the 
  value of the configuration parameter `play.http.secret.key`. Since the 
  docker image of the application is public, the secret key also needs to be
  provided in the externalized configuration file. See:

    http://playframework.com/documentation/latest/ApplicationSecret

- The play application uses a lock file while it is up.
  After a crash, the lock file stays put and prevents a restart.
  In order to be able to easily remove the lock file, it too is externalized
  to the host directory `/var/run/boardgame`. This directory needs to 
  be created before deployment.

- The script `prod-initial-setup.sh` creates the appropriate directories and
  a template of the external prod.conf file. To prepare the host machine,
  run the script and then edit the created prod.conf file to add in your host
  and port number to the allowed hosts configuration parameter, and your secret 
  encryption key.

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

