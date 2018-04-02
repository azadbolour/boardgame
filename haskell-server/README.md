
# Haskell Server

The game server exposes a game API, and uses a game end point to listen for client
requests used in playing the board game.

## Game API

The api is defined [here](http://www.bolour.com/boardgame/hdocs/BoardGame-Common-GameApi.html).
TODO. Not current. Update.

A user error, e.g., the user trying to commit a non-existent word is always 
indicated in the HTTP response by status code 422. The body of the response
includes the JSON encoding of the server side error. To find out the exact
nature of the error, the json needs to be analyzed by clients.

## Getting Started

See the steps in the Dockerfiles under the docker directory of the parent
project for the complete set of steps to set up your development environment
for development using the sqlite database. 

### Noteworthy in Setup

The Haskell project is built by using  [Haskell Tool Stack](https://docs.haskellstack.org).
See the file _stack.yaml_ for the Stack snapshot being used, and the file
_boardgame.cabal_ for the build and test specifications used by stack. 

`stack setup` will install the correct version of GHC (Glascow Haskell Compiler) in
an isolated sandbox. The correct version is automatically selected by 
Stack to match the stack snapshot version in _stack.yaml_. 

To see where the compiler was installed: `stack path`

Note that you do not need to separately install _cabal_ (the base Haskell 
build manager). It is best to just let stack handle cabal under the covers.

The haskell server uses a configuration file (provided as its first argument,
default config.yml). See the provided template config.yml.template. Typically
you copy this sample to config.yml and edit as appropriate. See the 
Configuration Parameters section below for a description of the available
parameters.
  
Note that config.yml is gitignored so that different developer environments may
have specific deployment configurations without interfering with each other.

Once you have succeeded in building the system, you use the scripts
`migrate-database.sh` and `populate-seed-data.sh` to create tables and 
populate them with initial data. To sanity check, make sure that the 
table _player_ has been created and include a single player _You_.

### Switching the DBMS

In addition to Sqlite (the default database), the project also supports
postgresql. See the docker files for installation of postgresql.

You'll need to create a database, and a user and password. All default to
_postgres_.

### Testing

Tests use their own configuration file: _test-data/test-config.yml_ which may
again be different for different users and is therefore gitignored. You may:

    `cp config.yml.template test-data/test-config.yml`

and if necessary edit as appropriate.
    
There are sample configuration files for both sqlite and postgresql
test-data directory. 

### Generating Haddock

`./gendocs.sh` uses stack to generate documentation in the project site
(under ../docs).

### Running the Game Server

`./run.sh` starts the server - takes the configuration file as a parameters
(default _config.yml_).

### Running Specific Test Suites

Specific test suites may be defined in the cabal file and run through stack.
But the process is a bit involved. We'll take a particular case as an example
of how to create and run specific test suites.

While developing a given a feature, it is useful to be able to run the tests
pertaining to that feature alone. For this purpose, a specific test suite is
defined in _boardgame.cabal_ called _infocus_ for tests that are currently in
focus. The specification of this suite in the _.cabal_ file includes a
specific main program (defined as `main-is: InFocus/Main.hs`) to run the suite.
The main program includes a list of the tests to run in its _spec_
specification.

To run the infocus test suite: `./run-test-suite.sh infocus`

You may define and run your own test suites in the same fashion.

### Tests against the Database

Make sure the database tables are up-to-date (use `migrate-postgres.sh` when
database structures change).

Tests are supposed to clear out and recreate the part of the database they need.
In case you need to explicitly clean out all data, use:

`./clear-postgres-db.sh`

### Profiling

To profile the application, the source files need to be compiled for profiling.

`./profile-bld.sh`

Then run the application in profile statistics gathering mode:

`./profile-run.sh`

### Configuration Parameters of the Game Server

As of version 0.2 the game server is configured through a YAML configuration
file. For now, the server does not support configuration through environment
variables. But should the need arise, environment variables overriding the 
configuration file may be easily be added. See Data.Yaml.Config for details.

The following configuration parameters are recognized:

- `serverPort` The port number on which the server listens. Default 6587.

- `dictionaryDir` The directory of dictionary files. The naming convention 
  for dictionary files recognized by the server is <languageCode>-words.txt.
  So for example, the generic English dictionary used by the server is the file
  within the dictionary directory named _en-words.txt_. If `DICTIONARY_DIR` is 
  not set, the default is the _data_ directory of the Haskell server. The
  contents of the project's _data_ directory are copied to the data directory 
  of the Haskell server (similar to resources in Java).

  By convention, the directory _dict_ is earmarked for specific dictionaries
  you may wish to use in testing, and is gitignored. To do testing with the MAC system
  dictionary, for example, link the system dictionary as follows:
  follows:

    ```
    cd dict
    ln -s /usr/share/dict/words en-words.txt`
    ```

  And use _dict_ as the dictionary directory in my config.yml file.

- `deployEnv` _dev_, _test_, and _prod_. 

- `maxGameMinutes` The maximum duration of a game in minutes. Default 30.
  Games lasting longer are subject to automatic termination without notice.

- `maxActiveGames` The maximum number of games that may be active at any 
  given time. Default 100 for version 0.1. Additional games cannot be started
  once this limit is reached, that is, until some existing games end or
  are timed out.
  
- `DbConfig` The configuration of the database. See the config.yml file for details.
  Sample config files for postgres and sqlite are also provided under
  the test-data directory. 


