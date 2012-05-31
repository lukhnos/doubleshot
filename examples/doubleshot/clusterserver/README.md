# clusterserver: DoubleShot's Take on the node.js cluster example

This is a  rewritten version of the node.js cluster example
(http://nodejs.org/docs/v0.6.0/api/cluster.html) using DoubleShot's
`submodule` and `asyncrun` primitives. The program creates *x* HTTP servers,
where *x* is the available CPU number on your machine.

The original program is as follows:

    var cluster = require('cluster');
    var http = require('http');
    var numCPUs = require('os').cpus().length;

    if (cluster.isMaster) {
      // Fork workers.
      for (var i = 0; i < numCPUs; i++) {
        cluster.fork();
      }

      cluster.on('death', function(worker) {
        console.log('worker ' + worker.pid + ' died');
      });
    } else {
      // Worker processes have a http server.
      http.Server(function(req, res) {
        res.writeHead(200);
        res.end("hello world\n");
      }).listen(8000);
    }

Our version goes like this:

    server = submodule
      console.log "server started"
      http = require 'http'  
      http.Server (req, res) ->
        res.writeHead 200
        res.end "hello world\n"
      .listen 8000

    numCPUs = require('os').cpus().length
    (asyncrun server) for i in [1..numCPUs]

Note that we don't handle the `death` event here. But there's nothing that
stops you doing that, since the object returned by `asyncrun` is really a
forked cluster instance on node.js. So you can also do this:

    installServer = () ->
      s = asyncrun server
      s.on 'death', (worker) ->
        console.log "worker #{worker.pid} died"
    installServer() for i in [1..numCPUs]

