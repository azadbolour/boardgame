

# Board Game Application Backlog

## System Improvements

- User registration. Currently there are no registered users. Just a built-in
  one called _You_. Use a microservice and if affordable, and external service.

- Button to end the game at any time.

- If the board is completely full, end the game automatically.

- Add dictionaries for other languages to the system. Allow user to 
  choose the game's language.

- Provide user preference page. Include user's preferred language.

- Disable play and show hourglass while an action is happening.

- Improve error reporting in the UI from Scala server.

- Some two-letter words in the dictionary don't mean anything to me.
  Clean up two-letter words, and perhaps add in common abbreviations.

  Get list of 2-letter words.  `egrep '^..$' moby-english.txt`

  Provide a way for the user to see which two-letter words are allowed.
  Maybe a button or a hover action.

- Show all cross words found in the UI so user can ascertain their meanings.

- After a game ends, start game should be enabled again.

## User Suggestions

- Provide a 'vowels' option: if checked the tray is guaranteed to have at least 
  one vowel.

- Towards the end of the game, based on the values remaining in open slots on 
  the board it becomes decidable whether the losing side can possibly catch up. 
  If the user is on the losing side, an option may be provided to resign.

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

- Graceful message when server is down. Currently the user gets no message.
  But the console gets the undecipherable message (bug): "Cannot read property
  kill of undefined."

## Technical Debt

- Write low-level tests for persistence of games.

- Currently storage of games in the database is not in focus. 
  Restoration of games from teh database remains to be implemented.

- Add error boundary for React.

- The game cache should go under the persistence layer.
  An LRU cache would be simplest. The current cache is used as a list
  of live games. Just keep a list of live game ids only so abandoned games
  can be detected and harvested.

    https://twitter.github.io/util/docs/com/twitter/util/LruMap.html

- Make sure adequate tests exist and pass for the service layer with 
  slick json persistence.

- Validate a piece placed on the baord - must be upper case alpha.

- Deploy to the AWS ECS - elastic container service. Use Fargate for 
  pay-as-you-go. 

- Implement the database layer on Amazon DynamoDB and connect from 
  the Fargate container. Reasonably-priced peristent store. Store entire 
  games in a JSON string. Users. Ownership of games by users.
  Haskell bindings for Amazon services: amazonka.

- Use docker compose to seamlessly upgrade the application.
  
  https://docs.docker.com/compose/gettingstarted/#step-4-build-and-run-your-app-with-compose
  https://docs.docker.com/compose/compose-file/#environment

- Blue-green deployment for the application.

- Getting stack traces on errors in Haskell requires profiling.
  Profiling may have something like 30% space overhead and some
  (unknown) performance overhead. But locating errors occurring 
  in production is not optional!

  So production code should be compiled with profiling.
  Just understand the memory and performance differences for this application.

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

- In production mode need to have obscure postgres user/password. Best practices for security
  to postgres in production mode? Needs to be set in the production deployment
  script. Best practices for password protection. Make sure postgres port is 
  closed to the outside. For now we are just using sqlite.

- Logging - debug versus info in all projects.

- Clean up tests.

- Try to get an exception from persistence. Then translate it and all such exceptions.
  Create a test for it and check if the exception is caught.

- Use a config parameter for the stale game harvester interval. Add it to run.sh.

- Standardize errors sent to the client so we get the same API behavior from all
  servers.

- Test for cache full.

- Check that all possible javascript exceptions are handled at 
  the highest level - use React top-level handler for components.

- Performance of large databases. Indexing. 

- Use JSHint for Javascript code.

- Was unable to upgrade to GHC 8.0.1 or versions of Servant higher than 0.6.1 - 
  versioning issues with the rest of the dependencies. Upgrade when possible.

- Add top-level script to build all dependent projects.

- CICD. Integrate with TravisCI on github. Free for open source.

  http://chrispenner.ca/posts/homebrew-haskell
  https://github.com/ChrisPenner/haskell-stack-travis-ci
  `https://docs.haskellstack.org/en/stable/travis_ci/`

- CICD - Build statically linked haskell server to reduce the size of the 
  docker container. Build with Nix if possible for a better experience.

- Javascript bundle cache busting. A good blog on how to use webpack plugins 
  to uniquely name javascript bundles by using hashes, and generate the index.html 
  page to use the unique name by using a template for that page.
  
  https://medium.com/@tomaskoutsky/hey-webpack-can-you-bust-my-cache-21350f95122t
  
  See the following for using a standalone index.html file in play:

  https://stackoverflow.com/questions/11126678/how-can-i-render-a-simple-html-page-using-play-framework

  Will have to set up a route like this:
  
  GET / controllers.Assets.at(path="/public/html", file="index.html")
 
## Development Nice-to-Haves

- Use NIX to build the Haskell server. Better solution than using docker.
  Can still copy the executable and any special libraries to a docker image
  for deployment to ECS.

- Try to use the Play docker plugin to generate the docker 
  image for play. Need to work out how to provide allowed hosts and
  the play secret in a secure manner to the server created by the plugin.

   https://medium.com/jeroen-rosenberg/lightweight-docker-containers-for-scala-apps-11b99cf1a666

- Check that you can debug minimized UI code with source maps in chrome.

- Put the persistence layer in a microservice so we won't have to port it to 
  the specific database access facilties of different languages. Learning the 
  specific and sometimes arcane bahaviors of all different database packages 
  for different languages is not the best use of our time.

  Perhaps use GraphQL.
