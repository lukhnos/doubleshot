# DoubleShot: A CoffeeScript Dialect with Cross-Platform Concurrency Primitives

DoubleShot is a CoffeeScript dialect that adds two concurrency primitives to
the language: `submodule` and `spawn`. A submodule defines an
independently-scoped program, which can be then spawned from the main program
as workers. The main program and the workers communicate with a message
passing mechanism.

Currently DoubleShot programs can be compiled to two "platforms": the web
browser, using HTML5 workers; and node.js, using the `cluster` library. The
concurrency model is the same as the HTML5 worker: share-nothing actors with
heavy setup and teardown costs. It is possible to extend the DoubleShot
compiler to generate JavaScript code using other concurrency libraries.


## Motivations

The motivation of DoubleShot is to provide a set of cross-platform concurrency
primitives for CoffeeScript. The current HTML5 worker and node.js cluster
library have their respective issues. The HTML5 standard requires workers to
be loaded from separate URLs, meaning they have to be written as separate
programs. There are non-standard ways to load the workers within the same
program, but that is not supported in all modern browser and involves DOM
manipulation. node.js cluster uses fork to implement the workers and requires
delicate setup to separate the master and worker code.

Since CoffeeScript already provides a level of abstraction from JavaScript, we
can build upon its compiler infrastructure to do the code generation and
rewriting for our concurrent programs. When DoubleShot targets HTML5 worker,
it generates separate JavaScript programs for respective submodules. When it
targets node.js cluster, it performs code motion to provide proper setup for
the master and workers. It also provides a unified message-passing API.
Concurrent programs written in DoubleShot can therefore be easily reused
across the different client- and server-side platforms by simply recompiling.


## Compiling DoubleShot Programs

DoubleShot adds two additional options to CoffeeScript`s `coffee` frontend:

*   -N generates JavaScript code that runs on node.js
*   -W generates JavaScript code, along with separate worker files, for HTML5
    worker

## Example

The `basicworker` sample app demonstrates how a simple master-worker program
can be run on both node.js and web browser.

To run on web browser:

    coffee -Wc main.coffee

Then copy `index.html` and the generated `.js` files to a folder to which you
have web server access. For security reasons most web browsers forbids loading
web workers from `file://` URLs. I've put up the example at
http://lukhnos.org/doubleshot/examples/basicworker/

To run on node.js:

    coffee -Nc main.coffee
    node main.js

Note that because of the way CoffeeScript and node.js cluster work (in short,
the forked process does not start at the point it was forked), it is
impossible to run the programs directly within `coffee`. That's why we need to
compile it to JavaScript first then run it with `node`.


## Basic Syntax

It is easy to define a submodule:

    foo = submodule 'foo-worker.js'   # the name is optional
        # define the submoudle here

The name in the example `'foo-worker.js'` is optional. It's really only used
when targeting HTML5 worker, and it tells the DoubleShot compiler to generate
the worker's JavaScript file under that name. If no name is given, a uniquely
numbered file name is assigned to each submodule.

Once you have defined a submodule, you can spawn a worker off it:

    worker = spawn foo
    # setup the communication
    worker.send 'a message'  # a string message
    worker.send cmd:'run', iteration:10  # an object message


## Setup the Communication between the Master and the Workers

In DoubleShot, the master and the spawned workers communicate with a
message-passing mechanism. The master *sends* messages to the workers, and
they *reply* to the messages. To setup how the master handles the response, do
this:

    worker = spawn foo
    worker.receive = (msg) ->
        # handle the receive here

In the submodule, the setup is similiar. Note that in a submodule, we use the
keyword `moduleSelf` to refer to the current program:

    foo = submodule
        moduleSelf.receive = (msg) ->
            # do some computations
            someReply = ...
            moduleSelf.reply someReply


## Submodules Can Spawn Themselves (Limited Support)

Submodules can spawn themselves:

    foo = submodule
        moduleSelf.receive = (msg) ->
            # some work requires sub-workers
            subworker = spawn moduleSelf

This corresponds to the HTML5 notion of *subworkers*. Unfortunately not every
browser supports it. As of writing only Firefox supports subworkers. On the
server-side, node.js cluster forbids forking from worker processes, although
it may be possible to modify the code.


## Termination

The worker can close itself:

    moduleSelf.close()

(Note that in CoffeeScript you have to add the parentheses to call a method
with no arguments, otherwise you are just referring the method as an object.)

Similarly, the master can force-terminate the worker:

    worker.terminate()


## Error Handling

If a worker runs into an error, and the error propagates to the master, the
master can specify a handler for such error:

    worker = spawn foo
    worker.error = (err) ->
        # handle the err

To facilitate debugging, the handler currently only works for HTML5 worker
errors. When targeting node.js, exception raised in the worker is not caught
by a top-level catch, therefore an uncaught exception will die in place.


## Specifying the Worker Load Path for HTML5 Workers

One design flaw in the current HTML5 worker draft is that workers have to be
loaded with a separate URL, and current browser implementations are messy. For
example, all supporting browsers (Chrome, Safari, Firefox) loads workers from
the relative path of the *HTML page*, not the *master program script*. While
Chrome supports relative path in the worker load URL, Firefox doesn't support
it and you have to specify the full URL. This is a problem if your web site
has a layout like this:

    /
    /index.html
    /js
    /js/main.js
    /js/worker.js

To circumvent the problem, DoubleShot has a global variable with which you can specify the worker's load path (suppose the web site is example.com):

    <!-- works in Chrome -->
    <script>_submoduleLoadPath = "js/";</script>

    <!-- works in Firefox -->
    <script>_submoduleLoadPath = "http://example.com/js/";</script>

    <script src="js/main.js"></script>

Admittedly it's not an elegant solution. Better for the browser and standard
makers to fix the problem.
