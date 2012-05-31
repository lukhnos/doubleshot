# nonblocking: A Contrived Example of Non-blocking Server

nonblocking is a contrived example of how you can use node.js cluster to
create non-blocking servers (using DoubleShot's sugarcoating, of course).

The program implements two servers, one on port 8000 and one on port 9000.
When you fire requests to port 8000, the server continues to handle new
requests even though there are other computation tasks in the background
(for this example we just do some meaningless adding for 1 billion times).
So on the console you'll see something like this for three requests:

    received request
    received request
    received request
    handled request
    handled request
    handled request

On the other hand, if you fire requests to port 9000, the handler for one
request won't finish until the computation completes, so the server won't
be able to handle another incoming request. Here's what you'll see for
three incoming requests:

    received request
    handled request
    received request
    handled request
    received request
    handled request

Please note that it may *not* be a good idea to spawn a new instance for
computation every time you receive a request. A lot of details are skipped
here: You may want to reuse the same computation instance, and setup extra
event handlers so that when the computation task replies, the master program
can dispatch the reply to the originating HTTP request handler. You may also
want to cache the computed data, so that if the next incoming request asks
for the same data, you can return immediately without passing the request
to tho computation task.

