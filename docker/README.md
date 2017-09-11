
The base directory has a Dockerfile for creating a base image that contains
the build, test, and run dependencies of the haskell server and the web ui
as of a particular version. It takes a long time to create that. To build a
new version from scratch make sure you use the "--no-cache=true" option so 
that it will be rebuilt.

The current base is named: 

        `azadbolour/boardgame-base-v0.2`

What takes a lot of time in building that image is that the Haskell stack
has to downlaod sourfe and build all the dependencies of the haskell server.

To build from newer versions of the source code, use the docker file in the "latest"
directory. That starts from the above base, gets the latest source and builds it.
Because most of the haskell dependencies have already been built by stack, building
the latest should be quick.

However, we need to make sure that the base is not rebuilt (obtained from the cache)
but the the rest of the commands do not use the cache. I am not sure what is the 
best way of doing that. Probably to pull a specific SHA, so that the command to pull
will be different each time. Need to do this.
