# basicworker: A DoubleShot Sample App

This is a very simple app that shows you how to use the concurrency primitives
provided by the DoubleShot. DoubleShot is a CoffeeScript dialect that adds
cross-platform concurrency support to the base language. Read more about it
at https://github.com/lukhnos/doubleshot

The sample app can be run both as a web app on modern web browsers and as a
standalone program on node.js.

## Running the App on node.js

To run the sample app on node.js, please get and install DoubleShot, and
use its frontend (also called `coffee`) to compile:

    <DoubleShot path>/bin/coffee -Nc main.coffee
    node main.js

The `-N` option specifies that the compiler should generate the JavaScript
code that targets the node.js platform.
    
Please note that because of the way node.js's `cluster` library is designed,
it is impossible to run this program directly via the `coffee` frontend, i.e.
`coffee -N main.coffee` would not work.

## Running the App on Web Browsers

To compile the app as a web app, use the `-W` (for workers) option:

    <DoubleShot path>/bin/coffee -Wc main.coffee

The compiler will also generate the JavaScript files for the declared
submodules. After compiling, deploy all the `.js` files along with the
`index.html` to a web server, and point your browser to that location.

I've also put up the sample app at: http://lukhnos.org/doubleshot/examples/basicworker/


## Code Walkthrough

The entry point of the main program, the `run` function, sets up a worker and
then sends a message to the worker:

    worker = spawn workerModule

    # set up the worker
    worker.receive = (data) ->
      log "Received from worker: " + JSON.stringify(data)
    worker.error = (err) ->
      log "Error within worker: " + JSON.stringify(err)

    # send the message
    worker.send(data)

A worker is defined by a "submodule" in DoubleShot, which has its own
independent scope (i.e. a submodule inherits nothing, scope-wise, from the
encompassing scope in which the submodule is declared). Once a submodule is
spawned, the code inside the submodule gets run in its declared order:

    workerModule = submodule
      # this code gets to run first
      setupMsg = "Welcome to worker program!"

      # setup the communication
      moduleSelf.receive = (msg) ->
        moduleSelf.reply "Some message: " + setupMsg
        moduleSelf.close()

