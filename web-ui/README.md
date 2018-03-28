

# The React DND User Interface of Board Game

The user interface makes use of the React DnD library for moving tiles 
on the board. 

See the
[React DND Tutorial](https://react-dnd.github.io/react-dnd/docs-tutorial.html)
and the rest of the React DND documentation for orientation.

## Getting Started

The steps required to install all the dependencies of the web-ui sub-project 
are scripted in the Dockerfiles in _docker_ directory of the server
sub-projects. These steps are for Ubuntu Linux. But you can follow 
the equivalent steps for other platforms. 

In particular, for the MAC, the first step is install node:

`
  brew update
  brew install node
`

Installs both node and npm.

## Development Server

For development purposes: Start a webpack development server to serve the
application with hot replacement of files:

  `npm start`

It should output: `Listening at http://localhost:3000/` and then start the
transpilation of the React JSX code by using the Webpack Javascript bundler.
Wait for the compilation to finish. It may take a few seconds.  Also ignore the
warning for the moment. This is a known issue.

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

## Running against the Game Server in Development Mode

First start the game server (see ../haskell-server/README.md).

Examples:

  - *http://localhost:3000?env-type=dev*  run against a game server listening on the default URL.
  - *http://localhost:3000?env-type=dev&game-server-url=http%3A%2F%2Flocalhost%3A8888*  
    run against a game server listening on the port 8888

## Running in Production Mode

- Build the production version of the React UI.

    bundle-prod.sh

  The production version will be found under the _dist_ directory.

  Note - bundle-prod.sh invokes the _bundle-prod_ script definition defined in
  the project's package.json. That script definition runs Webpack 
  using a production configuration to package the game application
  together with all its dependencies into a single javascript bundle.
  More details on Webpack below.

- Copy the produced bundle to the _static_ directory of the haskell server:

  `
  cd ../haskell-server
  update-ui-bundle.sh
  `

- Then bring up the haskell server and point your browser to:

  http://localhost:6587/boardgame

### About the Webpack Development Server 

In development, the machinery used to provide the application's Javascript and other assets
to the browser involves:

1. A server (provided by Webpack), called the _Webpack Development
   Server_ that watches for changes to source files. This server 
   is specified in the file _server.js_.

2. A client API layer for the Webpack Development Server that is provided 
   to the browser and mediates requests for Javascript and other resources,
   routing them through the Webpack Dveleopment Server to get the latest 
   copies of resources without restarting the application.

Generally when using Node, various development commands are specified in Node's
_package.json_ file. In particular, starting the webpack development server is
encoded in our package.json, as:

`
  "scripts": {
    "start": "node server.js"
`

The command `npm start` then reads this specification and runs the Node
command starting the server.

A better name for 'server.js' might have been _run-webpack-dev-server.js_.

Note that server.js imports webpack and webpack-dev-server, both specified
as the development dependencies in the project's package.json file.

The file _webpack.config.js_ includes information about the files needed by the
web application, and about how these files are to be processed before they get
served up by webpack in development mode. The _entry_ list in that file provides
the roots of the dependencies of the web application. In particular, one
dependency of the web application is the webpack-dev-server's client access
layer which allows the web application to obtain the latest versions of 
the application files. This is the entry:

`'webpack-dev-server/client?http://localhost:3000'`

in the webpack.config.js file. The other entry in that file is the the index.js
file, the actual entry point to the web application.

Note that in order to build a React application we are using an older version 
of Webpack (2.x). Trying to use the latest Webbpack (version 3.4.1) led to version 
dependency hell with other packages, and was abandoned. 

Note, however, that at this time (July 2017) all the official React samples I
have seem use Webpack 1.x. We moved to 2.x in order to be able to easily use the
webpack plugins for minification and uglification in production. Did not see
how (if?) one can use these plugins with webpack 1.x.

Note also, that the standard for package management for React has now moved on
to use Yarn. But this project has not taken that leap yet.

Note that calling 'webpack' without any parameters uses the default
_webpack.config.js_ and creates a bundle that is dependent on the webpack
development server.  By contrast the build script runs webpack by giving it the
configuration file _webpack.prod.config.js_ which is independent of the webpack
development server.

Note. For convenience in testing the production version, the file _myindex.html_
in the this directory (web-ui) is set up to use the production bundle under the
_dist_ directory. Simply point your browser to myindex.html to test the production
version.

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
or drop targes.

One of the injected properties is a rendering wrapper provided by the framework
that must be used to wrap the component's JSX XML specification. It is called
respectively _connetDragSource_ and _connectDropTraget_. 

For the drag source, another required property to inject is _isDragging_, again
provided by the framework.

For the drop target other properties to inject are _isOver_ and _canDrop_. These
are also provided by the framework. The framework's canDrop function in turn
calls the canDrop function of the dropper object, if it exists.

For sample code see the source files `PieceComponent.js` for drag source, and
`BoardSquareComponent.js` for drop target.


