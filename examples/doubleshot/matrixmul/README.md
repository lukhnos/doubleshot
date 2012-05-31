# matrixmul: Computation Tasks that Don't Block Your UI

This is a more sophisticated sample for DoubleShot, demonstrating how to write 
a program with concurrent computation tasks. DoubleShot is a CoffeeScript 
dialect that adds cross-platform concurrency support to the base language. 
Read more about it at: https://github.com/lukhnos/doubleshot

You can try the app on the web: 
http://lukhnos.org/doubleshot/examples/matrixmul/

In each of the test cases, two random matrices are generated then get 
multiplied by one or more workers. On modern browsers each worker runs in its 
separate thread or process. For computations that take a long time, using 
workers has the benefit that it doesn't block the UI, making the user 
experience better. Since the master program and the workers communicate with a 
message-passing mechanism, jobs can be queued. You can try hitting the above 
buttons in quick succession to see that effect.

This app does not try to implement efficient matrix multiplication nor 
effective matrix representations. The point is to show how you can use 
DoubleShot to simply the program organization.

On a multicore machine, the 2-worker version runs anywhere from 10% to 30% 
faster than the 1-worker version (for the 500x500 data set), so indeed the 
browsers are using multiple cores. The reason we are not seeing a 80+% 
improvement is that passing large data structures between master and worker is 
expensive. There is a faster way to pass those data, but it is not supported 
by all browsers and it also involves changing the matrix representation, so 
I'm not doing it for the demo's purpose.

## Running the App on node.js

Since DoubleShot is cross-platform, this app can also be run as a standalone 
node.js program. Please get and install DoubleShot, and use its frontend (also
called `coffee`) to compile:

    <DoubleShot path>/bin/coffee -Nc matrixmul.coffee
    node matrixmul.js

## Running the App on Web Browsers

To compile the app as a web app, use the `-W` (for workers) option:

    <DoubleShot path>/bin/coffee -Wc matrixmul.coffee

The compiler will also generate the JavaScript files for the declared
submodules. After compiling, deploy all the `.js` files along with the
`index.html` to a web server, and point your browser to that location.
