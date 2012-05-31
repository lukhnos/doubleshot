
nonBlockingCompute = submodule
  moduleSelf.receive = (msg) ->
    
    # do some long computation...
    i = 0
    k = 0
    while i < 1000000000
      i++
      
    moduleSelf.reply "result"
    moduleSelf.close()


http = require 'http'  

# the non-blocking handler
http.Server (req, res) ->
  console.log "received request"
  
  c = asyncrun nonBlockingCompute
  c.receive = (msg) ->
    res.writeHead 200
    res.end "hello world\n"
    console.log "handled request"
  c.send "compute"
.listen 8000


# the blocking handler
http.Server (req, res) ->
  console.log "received request"
  
  # do some long computation...  
  i = 0
  k = 0
  while i < 1000000000
    i++

  res.writeHead 200
  res.end "hello world\n"
  console.log "handled request"
.listen 9000
