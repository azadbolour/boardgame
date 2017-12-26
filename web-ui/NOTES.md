
- On MAC got the following error after a clean npm install. 

  xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory 
  '/Library/Developer/CommandLineTools' is a command line tools instance

  Reinstalled developer command line tools and the error did not go away.
  Could not see solution. Decided to ignore for now.

- Always use arrow functions when passing a component method to an inner render 
  handler. Otherwise, this will be undefined when the "method" executes.

- Use pre tags for spaces and just add spaces. Do not use &nbsp; it gets turned
  into circumflex A in unpredictable ways when using srevant and react.

- jest - test.only and test.skip.

- Use let instead of var. Use const where possible.

- http://racingtadpole.com/blog/test-react-with-jest/

- https://react-dnd.github.io/react-dnd/docs-testing.html

- http://www.2ality.com/2014/09/es6-modules-final.html

- https://reactjsnews.com/testing-drag-and-drop-components-in-react-js

- Modules imported with require are mocked automatically in jest.

- Jest provides an it.only() function to run a single test. 

- This depends on caller of function - review your own notes.
  Read the javascript the best parts book again. Also the secrets.

- Multiple thens can have the same catch. The implementation of
  when then goes wrong calling the reject function remains a mystery.

  The implementation of how tests wait for promises to be 
  fullfilled remains a mystery.

- Good writeup on js modules and import:

    http://www.2ality.com/2014/09/es6-modules-final.html
    You shoulid just use that.

- Rather than module.exports use export default something.
  You can still export other stuff by prefixing - like public.

- https://facebook.github.io/jest/docs/tutorial-async.html

- Promises, futures, and monads in JS.

  https://hackernoon.com/from-callback-to-future-functor-monad-6c86d9c16cb5#.5ff3cjepw
  https://blog.jcoglan.com/2011/03/11/promises-are-the-monad-of-asynchronous-programming/

  Is this really the api?

      resolve(response.json) - actually should just get an object not json
      reject(response.status, response.json()) - again it should just be an error object
        or response.json.meta.error

- Cannot have 2 html5 backends at the same time. Put the context at the highest level.
  The lower levels will inherit.

  https://github.com/react-dnd/react-dnd/issues/186

- https://react-dnd.github.io/react-dnd/examples-dustbin-single-target.html

  return (
      <DragDropContextProvider backend={HTML5Backend}>

- https://github.com/facebook/jest/tree/master/examples/react
  https://facebook.github.io/jest/docs/tutorial-react.html
  https://facebook.github.io/jest/docs/getting-started.html
  https://facebook.github.io/jest/docs/api.html
  https://github.com/facebook/jest/blob/master/examples/snapshot/__tests__/Link.react-test.js
  https://facebook.github.io/jest/docs/expect.html

- console.log(`move: ${JSON.stringify(move)}`);

- https://developers.google.com/web/fundamentals/getting-started/primers/promises

  this is a pretty thorough explanation

- fetch https://davidwalsh.name/fetch 

- https://davidwalsh.name/fetch

- javascript promise notes

  http://www.datchley.name/es6-promises/

  var p = new Promise(function(resolve, reject)

  The resolve callback is called when the value becomes available.
  The reject callback is called if the value can't be provided.

  var p = Promise.resolve(42);

  Q: Is there a relationship between resolve and then, reject and catch?
  Who provides the resolve and how is the "then" called when resolve is called?
  Who provides the reject ditto.

  catch is a shorthand for then(null, rejectHandler)

  A return value from a then is automatically wrapped in a promise.
  That is why then's can be chained.

  Can use just one catch at the end of a promise chain.

  Looks like you can have multiple chains attached to a single
  promise.

  One thing that is confusing is that the promise api confounds
  promises with values. Automatic warpping and unwrapping 
  in promises reduces code bulk, but obsures semantics.

  Here is an example from http://www.datchley.name/promise-patterns-anti-patterns/:

  firstThingAsync()  
  .then(function(result1) {
    return Promise.all([result1, secondThingAsync(result1)]); 
  })
  .then(function(results) {
    // do something with results array: results[0], results[1]
  })
  .catch(function(err){ /* ... */ });

  Is result1 a promise or a value inside a promise? It is both
  depending on context. In the context of Promise.all it is a promise.

  But now the semantics get complicated because we have to specify 
  the places where wrapping and unwrapping take place to fully understand
  what is going on.

  Interesting chaining example from same blog:

  // Promise returning functions to execute
  function doFirstThing(){ return Promise.resolve(1); }  
  function doSecondThing(res){ return Promise.resolve(res + 1); }  
  function doThirdThing(res){ return Promise.resolve(res + 2); }  
  function lastThing(res){ console.log("result:", res); }
  
  var fnlist = [ doFirstThing, doSecondThing, doThirdThing, lastThing];
  
  // Execute a list of Promise return functions in series
  function pseries(list) {  
    var p = Promise.resolve();
    return list.reduce(function(pacc, fn) {
      return pacc = pacc.then(fn);
    }, p);
  }
  
  pseries(fnlist);  


- Problem trying to solve - make two async calls in succession.
  Each can be rejected or can return a !OK status but not rejected.

  https://stackoverflow.com/questions/33445415/javascript-promises-reject-vs-throw

  http://2ality.com/2016/03/promise-rejections-vs-exceptions.html

- Comments is JSX - use curly braces with javascript block comments.

            {/*
            <div>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</div>
            <div style={paddingStyle}>
              <button onClick={this.machinePlay} style={buttonStyle()}>Machine Play</button>
            </div>
            */}

- React documentation:

    https://facebook.github.io/react/docs/hello-world.html

- If you need something to change in the UI without explicit re-rendering,
  you need to change the state of the component, and have the UI element's
  look depend on the state. For example, you can define a state variable 
  for the component that the cursor is currently on top of, and show a 
  a tool tip for that component conditionally. Conditional rendering 
  uses the following idiom:

  `{someCondition && <div>render me</div>}`

  The condition may use state variables.

- Seems like the recommendation is to use functional components
  (components defined by a function) for stateless components that 
  do not need lifecycle functions, and use classes inheriting
  from component if you need state or lifecycle support.
  
  https://medium.com/@dan_abramov/how-to-use-classes-and-sleep-at-night-9af8de78ccb4

  I am using the older createClass style. For now will not change to use classes.
  As this area of React seems to be in a state of flux and classes 
  are not looked upon all that favorably in much of the javascript 
  community (circa mid 2017).

  You might try to change to stateless functional components where
  possible however.
