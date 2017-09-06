
# Board Game Application Backlog

## The Release

### Prepare Release

- Test with in-memory sqlite. Will need to do migration in main.
  In-memory sqlite does not yet work. Since stored data is not currently
  being used afte a game has ended, for simplicity of initial release
  administration, we'll just use in-memory sqlite, finessing the need
  to administer a postgres server.

- Convert to gradle. util and benchmark converted. java-client,
  and boardgame-benchmark should be easy: gradle init.

- Already added warnings from maven for boardgame/benchmark build. 
  Unsure whether this is an issue. Will go away once converted to gradle.

- Prepare project web site.

- Refer to API documentation from the index.html of the project site.

- publish util and benchmark jars - should not be snapshot - include manifest

- Create release branch.

- Benchmark on EC2.

## Known Issues

- Security. CORS. Generally cross origin requests are disallowed. 

  But in doing web development, we use the webpack server at localhost:3000 for
  the Javascript and access the Servant server.  We are able to do the latter,
  but not in a verifiably secure manner yet.  manner yet.

  Adding "http://localhost:3000" to 'Access-Control-Allow-Origin' in the server
  has not worked for me.

  https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS

  https://www.html5rocks.com/en/tutorials/cors/

- Security. User registration and basic authentication for users. 

  http://haskell-servant.readthedocs.io/en/stable/tutorial/Authentication.html

  Use this for basic authentication. 
  
  Add 'authorization' to the 'Access-Control-Allow-Headers'.

  Https. Use tlsManagerSettings in http-client-tls instead of defaultManagerSettings.
  runTLS (tlsSettings "server.crt" "server.key") (setPort 8080 defaultSettings) app

  https://github.com/algas/haskell-servant-cookbook/blob/master/doc/Https.md

- Check that all cross words are legit on recieving a commit play.

- Provide a way of getting the meaning of a word played by the machine.
  Out of scope of version 1. Use the provided list view of played words to 
  copy and paste into Google or dictionary site.

- Disallow all URL parameters to avoid issues with bad URL.
  Create a preference page where you can set parameters.
  Save preferences in the database.

- In some circumstances, the change of color to green/yellow for legal move
  remains in place, and in some it gets triggered everywhere where it is allowed
  without the cursor actually traversing all thos locations. 

  The intent is to just track the cursor. Moving out should
  revert the change of color. 

  Not easy to duplicated.

  Moving out of the board and back in quickly sometimes triggers this 
  type of behavior. Might also be related to using remote ThinLinc window
  to Linux.

## Technical Debt

- For all Haskell data structures decide what fields are public and only export those.

- Code duplication for caching in GameCache. Should just use Cache for Game. See TODO
  comment of GameCache.

- Publish the github site for boardgame.

- See also TODO and FUTURE comments in the code base.

- On initial startup - check that at least the english dictionary exists in the 
  specified directory. If not abort.

- The client API needs to distinguish between user errors 422
  and other server errors.

- Benchmark think time configuration is currently the maximum. It should be
  the average. Fix PlayPersona. Also provide a generic default implementation
  for getThinkTime in abstract persona.

- Play number is not incremented properly in all cases.  Machine play does not
  get an updated number if it is a swap. Regular plays seem to update. See
  reflectPlayOnGame. Should be centralized in a call and called initially in
  service methods.

- An internal error should end the game in the server, and also in the UI.

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

- When running with production version:

  warning.js:35 Warning: It looks like you're using a minified copy of the
  development build of React. When deploying React apps to production, make sure
  to use the production build which skips development warnings and is faster.
  See https://fb.me/react-minification for more details.

  Have to add this to the prod config of webpack for real production.

  ```
  new webpack.DefinePlugin({
    'process.env': {
      NODE_ENV: JSON.stringify('production')
    }
  }),
  ```
- Webpack warnings, e.g., for node-fetch - can they be fixed?

- Create a docker image for the executable server.
  
  https://github.com/commercialhaskell/stack/blob/master/doc/docker_integration.md

  https://www.fpcomplete.com/blog/2016/10/static-compilation-with-stack

  There are flags to even include the system libraries into the haskell image.

- migrate-database.sh needs to use the correct database parameters
  to insert or update data. For now it assumes postgres on current machine 
  and no password. Insertion of initial data should be done in the program.
  
- Not sure to what extent Persistent migration can be trusted to do the right
  thing. Hence not migrating at every startup of the server. But we should
  either via Persistent migration or separate scripts or both.

- For in-memory sqlite database, we need to migrate and add initial data
  in main.

- Allow access to SQLite database to make it easier to host the application
  on hosting services. No database installation necessary.

- In production mode need to have obscure postgres user. Best practices for security
  to postgres in production mode? Needs to be set in the production deployment
  script. Best practices for password protection. Make sure postgres port is 
  closed to the outside.

- Create a docker image for development.

- New release of Ubuntu '16.04.2 LTS' available. Run 'do-release-upgrade' to 
  upgrade to it on teh production machine.

- Use Servant's enter functionality for cleaner end point code.

    https://haskell-servant.github.io/tutorial/0.4/server.html

    http://stackoverflow.com/questions/31279943/using-servant-with-readert-io-a

- Use LoggingT after ReaderT in transformer stack.

- Use NoContent instead of () in Servant API.

- Logging in server. How to restrict logging level in logging-effect?

- Add start time of game to database.

  https://www.schoolofhaskell.com/school/advanced-haskell/persistent-in-detail/persistent-time-values

- Clean up tests.

- Try to get an exception from persistence. Then translate it and all such exceptions.
  Create a test for it and check if the exception is caught.

- Use a config parameter for the harvester interval. Add it to run.sh.

- Use in-memory sqlite database for development and testing. Allow database
  to be parameterized in config file.

- Test for cache full.

- Check that all possible javascript exceptions are handled at 
  the highest level.

- Performance of large databases. Indexing. 

- Use JSHint for Javascript code.

- Stack has been installed to: /usr/local/bin/stack

  WARNING: '/home/ubuntu/.local/bin' is not on your PATH.
    For best results, please add it to the beginning of PATH in your profile.

- Was unable to upgrade to GHC 8.0.1 or versions of Servant higher than 0.6.1 - 
  versioning issues with the rest of the dependencies. Upgrade when possible.

- Upgrade React code to use class MyComponent extends React.Component.

- Add top-level script to build all dependent projects.

- Document main design patterns, idioms, and conventions.

- Check that you can debug minimized UI code with source maps in chrome.

- Integrate with TravisCI on github. Free for open source.

  https://github.com/ligurio/Continuous-Integration-services/blob/master/continuous-integration-services-list.md
  https://docs.haskellstack.org/en/stable/travis_ci/

