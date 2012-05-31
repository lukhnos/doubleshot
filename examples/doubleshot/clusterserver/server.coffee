#
# A rewritten version of the node.js cluster example
# (http://nodejs.org/docs/v0.6.0/api/cluster.html) using DoubleShot's
# submodule and asyncrun primitives
#

server = submodule
  console.log "server started"
  http = require 'http'  
  http.Server (req, res) ->
    res.writeHead 200
    res.end "hello world\n"
  .listen 8000

numCPUs = require('os').cpus().length
(asyncrun server) for i in [1..numCPUs]
