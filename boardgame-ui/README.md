

# The React DND User Interface of Board Game

The user interface makes use of the React DnD library for moving tiles 
on the board. 

See the
[React DND Tutorial](https://react-dnd.github.io/react-dnd/docs-tutorial.html)
and the rest of the React DND documentation for orientation.

## Getting Started

  `brew update`
  
  `brew install node`

Installs both node and npm.

Certain npm packages are installed globally - see global-installs.sh.
Note that to avoid merge conflicts for the file package-lock.json which 
is updated by npm, global-installs.sh also installs npm-merge-driver
which is supposed to resolve git merge conflicts of the lock file 
automatically. See 

  https://github.com/npm/npm/blob/latest/doc/files/npm-package-locks.md#resolving-lockfile-conflicts

I used create-react-app to create the the empty boardgame-ui project,
ignored the generated source files and added my own sources. Then 
add the needed dependencies to package.json.

  `npx create-react-app boardgame-ui --use-npm`

  `npm install`
  
  `npm start`

See the generated package.json file for the available npm commands.

## Development Server

For development purposes: Start a webpack development server to serve the
application with hot replacement of files:

  `npm start`

It should output: `Listening at http://localhost:3000/` and then start the
transpilation of the React JSX code by using the Webpack Javascript bundler.
Wait for the compilation to finish. It may take a few seconds.  

For work on the UI only (using a mock API in the browser), point your browser to
the above URL:

    `http://localhost:3000?env-type=dev&api-type=mock`

This brings up the UI in development mode using a mack game API 
implementation in teh browser.

## Configuring the Game UI Parameters

In version 0.5, game parameters are provided within the URL used to bring up
the application. Following are the configuration parameters.

- env-type - valid values _dev_, _test_, _prod_ - default _prod_.
  The deployment context of the program.

- api-type - valid values _mock_, _client_ - default _client_.
  The api implementation to use - _mock_ is a fully browser-based
  mock implementation of the game API used for UI testing only;
  _client_ is the client-side library implementation of the API
  talking to the game server.

- game-server-url. The base/origin URL of the game server that the client-side
  API should connect to. The default depends on the env-type. In production mode
  this parameter is not a settable (it is ignored) and is always set to the 
  origin of the web application - where it was loaded from. In the dev and test
  environments, the default is _http://localhost:6587_.

- dimension - The dimension of the game grid. Valid range: [5..15]. Default 15.
  
- tray-capacity - The number of slots in the available letters list. Valid
  range: [3..10]. Default 7.
  
- square-pixels - The length in pixel of the side of a square in teh grid and
  and in the tray. Valid range: [15..60]. Default 33.

## Building the Production Bundle

  `npm run build`

This is scripted in `build.sh`.

To run a node server using the built app:

\`npm config get prefix\`/bin/serve -s build
  

## Running against the Game Server in Development Mode

Examples:

  - *http://localhost:3000?env-type=dev*  run against a game server listening on the default URL.
  - *http://localhost:3000?env-type=dev&game-server-url=http%3A%2F%2Flocalhost%3A8888*  
    run against a game server listening on the port 8888

## React Drag and Drop Notes

The design pattern required by the React drag and drop library is somewhat
complicated. Here I will provide an overview. See the React DND documentation
for details.

In order to be able to drag a component, that component's class must be
decorated as a _DragSource_. The decoration assigns an _item type_ and a
_dragger object_ to the corresponding components. 

The item type is matched in the drop procedure to the item types acceptable by
components receiving the dragged item. 

The dragger object has callbacks for the begin and end drag events, and for
whether a particular instance of the component can be dragged. The begin
callback creates and returns what is called a [drag] _item_, a simple Javascript
object with information about the component being dragged. The item properties
can later be inspected and used to direct the drop procedure.

In order to be able to drop something onto a component, the class of that
component needs to be decorated as a _DropTarget_. The decoration provides
information about what types of items may be dropped, and how a drop is processed.

To tell react DND what happens in a drop, you create a _dropper_ object.
The dropper object generally defines [at least] two functions, _canDrop_ and _drop_.
The function 'canDrop' tells React DND if a dragged item can be dropped on a given 
component. The function 'drop' is the callback for the event of dropping a dragged
item. Each function takes two parameters: props: the properties of the component 
receiving the dragged item (the drop target), and monitor: an object that knows about 
the dragged item and is monitoring its movement.

The tricky part is that one has to tell the framework to inject certain
properties into drag sources and drop targets, in order for these components to
behave properly. This is done by a callback function, that by convention is
called _collect_ in each case. However, I have used the names
_injectedDragSourceProperties_ and _injectedDropTargetProperties_ to remind
myself about what these functions do. These functions return Javascript objects
that includes the properties to be injected into the corresponding drag sources
or drop targets.

One of the injected properties is a rendering wrapper provided by the framework
that must be used to wrap the component's JSX XML specification. It is called
respectively _connectDragSource_ and _connectDropTarget_. 

For the drag source, another required property to inject is _isDragging_, again
provided by the framework.

For the drop target other properties to inject are _isOver_ and _canDrop_. These
are also provided by the framework. The framework's canDrop function in turn
calls the canDrop function of the dropper object, if it exists.

For sample code see the source files `PieceComponent.js` for drag source, and
`BoardSquareComponent.js` for drop target.

### Note on upgrade to react-dnd 9.4. Oct 2019.

The react-dnd tutorial now uses an API that relies on React hooks, 
a new feature. This feature only works with components that are functions. 

Our components are classes. So unless we do a major refactor to convert 
our components to functions, we cannot use the methods described in the latest version of the tutorial. 
It is recommended that hooks only be used for new development. So we will not destabilize our UI by 
doing a major refactor for now.

It is unclear whether the old way of using component decorators for drag and drop 
is now legacy. That is because the examples have two versions, a decorator version and a hook version. 
So it seems safe to assume that the decorator version is not deprecated.

