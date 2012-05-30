matMul = submodule

  mul = (a, b) ->
    ra = a.length
    throw "Invalid dimension" if ra < 1
    ca = a[0].length
    throw "Invalid dimension" if ca < 1    
    rb = b.length
    throw "Invalid dimension" if rb < 1
    cb = b[0].length
    throw "Invalid dimension" if cb < 1
    throw "Matrices cannot be multiplied" if ca != rb

    rr = new Array(ra)
    r = 0
    while r < ra
      rc = new Array(cb)
      c = 0
      while c < cb
        p = 0
        i = 0
        while i < rb
          p += a[r][i] * b[i][c]
          i++
        rc[c] = p
        c++
      rr[r] = rc
      r++
    rr

  moduleSelf.receive = (msg) ->
    log = () ->
    log = console.log if console?
    
    ackMsg = "partition #{msg.partition}: received data"  
    moduleSelf.reply {ack: ackMsg}
    mc = mul(msg.a, msg.b)
    
    moduleSelf.reply {result: mc}
    log "partition #{msg.partition}: sent result"


(exports ? this).Matrix = 
  toStr: (m, maxLen) ->
    maxLen = 3 if !maxLen?
    
    numFormatter = (n) ->
      nstr = n.toString()
      slen = nstr.length
      spcnt = if slen >= maxLen then 0 else (maxLen - slen) + 1
      Array(spcnt).join(" ") + nstr
    
    rowFormatter = (r) ->
      (numFormatter(c) for c in r).join(" ")
    ((rowFormatter r) for r in m).join("\n")

  random: (r, c, max) ->
    max = 9 if !max?
    (Math.floor(Math.random() * max) for x in [1..c]) for y in [1..r]
    
  zero: (r, c) ->
    (0 for x in [1..c]) for y in [1..r]
    
  identity: (r) ->
    m = this.zero(r, r)
    i = 0
    while i < r
      m[i][i] = 1
      i++
    m
    
  slowMul: (a, b) ->
    ra = a.length
    throw "Invalid dimension" if ra < 1
    ca = a[0].length
    throw "Invalid dimension" if ca < 1    
    rb = b.length
    throw "Invalid dimension" if rb < 1
    cb = b[0].length
    throw "Invalid dimension" if cb < 1
    
    throw "Matrices cannot be multiplied" if ca != rb
    
    dotProd = (x, y) ->
      i = 0
      l = x.length
      p = 0
      while i < l
        p += x[i] * y[i]
        i++
      p
    
    col = (m, c) ->
      r[c] for r in m

    (dotProd(r, col(b, ci)) for ci in [0..cb-1]) for r in a
    
  parallelMul: (a, b, numSlices, onDone) ->    
    numSlices = 1 if !numSlices?
    aLen = a.length
    sliceSize = Math.floor(aLen / numSlices)
    finalResult = new Array(aLen)
    counter = (if (aLen % numSlices == 0) then numSlices else numSlices + 1)    
    
    doMul = (aSlice, fromIndex, partition) ->
      toIndex = fromIndex + aSlice.length
      toIndex = aLen if toIndex > aLen
      console.log "spawning partition: #{partition} [#{fromIndex}, #{toIndex})"
      mulTask = spawn matMul
      mulTask.receive = (msg) ->
        if msg.ack?
          console.log "received worker ack: " + msg.ack
        else if msg.result?
          j = 0
          while j < aSlice.length
            finalResult[j + fromIndex] = msg.result[j]
            j++

          mulTask.terminate()
          counter--
          if counter == 0
            console.log "done"
            onDone(finalResult)

      console.log "sending data to partition: " + partition
      mulTask.send({a:aSlice, b:b, partition:partition})

    i = 0
    partition = 0
    while i < aLen
      as = a.slice(i, i + sliceSize)
      if as.length > 0
        doMul(as, i, partition)

      i += sliceSize
      partition++



(exports ? this).runDemo = (dimension, numSlices, userOnDone) ->
  numSlices = 1 if !numSlices?
  dimension = 10 if !dimension?

  a = this.Matrix.random dimension, dimension
  b = this.Matrix.random dimension, dimension

  makeOnDone = () ->    
    start = new Date().getTime()    
    onDone = (result) ->
      elapsed = new Date().getTime() - start
      userOnDone result, elapsed
  
  this.Matrix.parallelMul a, b, numSlices, makeOnDone()


if typeof this.window == "undefined"
  console.log "Run demo under node.js, 1000x1000"
  
  onDone = (result, elapsed) ->
    console.log "elapsed time: #{elapsed} ms"
  
  this.runDemo 1000, 2, onDone
      
