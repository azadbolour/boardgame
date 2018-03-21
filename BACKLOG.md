

# Board Game Application Backlog

## System Improvements

- User registration. Currently there are no registered users. Just a built-in
  one called _You_.

- Button to end the game at any time.

- If the board is completely full, end the game automatically.

- Add dictionaries for other languages to the system. Allow user to 
  choose the game's language.

- Provide user preference page. Include user's preferred language.

- Disable play and show hourglass while an action is happening.

- Add error boundary for React.

- Improve error reporting in the UI from Scala server.

## Known Issues

- Security. CORS. Generally cross origin requests are disallowed. 

  But in doing web development, we use the webpack server at localhost:3000 for
  the Javascript and access the Servant server.  We are able to do the latter,
  but not in a verifiably secure manner yet.  manner yet.

  Adding "http://localhost:3000" to 'Access-Control-Allow-Origin' in the server
  has not worked for me.

  https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS

  https://www.html5rocks.com/en/tutorials/cors/

- Security. Basic authentication for users. 

  http://haskell-servant.readthedocs.io/en/stable/tutorial/Authentication.html

  Use this for basic authentication. 
  
  Add 'authorization' to the 'Access-Control-Allow-Headers'.

  Https. Use tlsManagerSettings in http-client-tls instead of defaultManagerSettings.
  runTLS (tlsSettings "server.crt" "server.key") (setPort 8080 defaultSettings) app

  https://github.com/algas/haskell-servant-cookbook/blob/master/doc/Https.md

- Create a preference page where you can set parameters.
  Save preferences in the database.

- Graceful message when server is down. Currently the user gets no message.
  But the console gets the undecipherable message (bug): "Cannot read property
  kill of undefined."

## Technical Debt

- Validate a piece placed on the baord - must be upper case alpha.

- Deploy to the AWS ECS - elastic container service. Use Fargate for 
  pay-as-you-go. 

- Implement the database layer on Amazon DynamoDB and connect from 
  the Fargate container. Reasonably-priced pereistent store. Store entire 
  games in a JSON string. Users. Ownership of games by users by date.
  Haskell bindings for Amazon services: amazonka.

- Blue-green deployment for the application in docker containers.

- Getting stack traces on errors in Haskell requires profiling.
  Profiling may have something like 30% space overhead and some
  (unknown) performance overhead. But locating errors occurring 
  in production is not optional!

  So production code should be compiled with profiling.
  Just understand the memory and performance differences for this application.

- Representation of game in Haskell currently uses a single data structure for 
  the game as a whole and the game;s state. Separate these two concerns.

- Validate all API input arguments. In particular, pointValues is currently 
  not validated in the start game API call.

- For all Haskell data structures decide what fields are public and only export those.

- Code duplication for caching in GameCache. Should just use Cache for Game. See TODO
  comment of GameCache.

- See also TODO and FUTURE comments in the code base.

- On initial startup - check that at least the english dictionary exists in the 
  specified directory. If not abort.

- Benchmark think time configuration is currently the maximum. It should be
  the average. Fix PlayPersona. Also provide a generic default implementation
  for getThinkTime in abstract persona.

- Use database transactions. Put db calls inside runSqlPersistMPool.

- No timeout on calls from Javascript to the server. So technically
  the client can hang.

  Timeout all promises from fetch. It does not look as if there is a 
  standard timeout property in the fetch init parameter. 

  May have to implement our own by using a parallel promise that has a time for
  the timeout and using promise.race between that and the fetch request. 

  https://italonascimento.github.io/applying-a-timeout-to-your-promises/ 

  Also consider using async/await.

  http://stackoverflow.com/questions/37120240/timeout-in-async-await

  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function

  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/await

  If we time out on a fetch request, the fetch has to be cancelled. 
  Best practices for cancelling fetch?

- Webpack warnings, e.g., for node-fetch - can they be fixed?

- Add population of seed data to the docker file.

- Not sure to what extent Persistent migration can be trusted to do the right
  thing. Hence not migrating at every startup of the server. But we should
  either via Persistent migration or separate scripts or both.

- In production mode need to have obscure postgres user. Best practices for security
  to postgres in production mode? Needs to be set in the production deployment
  script. Best practices for password protection. Make sure postgres port is 
  closed to the outside. For now we are just using sqlite.

- Use Servant's enter functionality for cleaner end point code.

    https://haskell-servant.github.io/tutorial/0.4/server.html

    http://stackoverflow.com/questions/31279943/using-servant-with-readert-io-a

- Use LoggingT after ReaderT in transformer stack.

- Separate GameState from Game in Haskell server.

- Logging in server. How to restrict logging level in logging-effect?

- Add start time of game to database.

  https://www.schoolofhaskell.com/school/advanced-haskell/persistent-in-detail/persistent-time-values

- Clean up tests.

- Try to get an exception from persistence. Then translate it and all such exceptions.
  Create a test for it and check if the exception is caught.

- Use a config parameter for the stale game harvester interval. Add it to run.sh.

- Test for cache full.

- Check that all possible javascript exceptions are handled at 
  the highest level - use React top-level handler for components.

- Performance of large databases. Indexing. 

- Use JSHint for Javascript code.

- Was unable to upgrade to GHC 8.0.1 or versions of Servant higher than 0.6.1 - 
  versioning issues with the rest of the dependencies. Upgrade when possible.

- Add top-level script to build all dependent projects.

- Check that you can debug minimized UI code with source maps in chrome.

- Integrate with TravisCI on github. Free for open source.

  http://chrispenner.ca/posts/homebrew-haskell
  https://github.com/ChrisPenner/haskell-stack-travis-ci
  https://docs.haskellstack.org/en/stable/travis_ci/

