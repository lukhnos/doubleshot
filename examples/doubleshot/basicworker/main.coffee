#
# main.coffee: a simple example for master-worker setup
#

(exports ? this).run = (data) ->

  log = console.log
  log = this.window.alert if this.window?

  workerModule = submodule
    # this code gets to run first
    setupMsg = "Welcome to worker program!"

    # setup the communication
    moduleSelf.receive = (msg) ->
      if msg == "error"
        # x not defined, this generates an error that propagates to the master
        moduleSelf.reply 1/x
      else
        moduleSelf.reply "Master passed: " + msg +
          "; our setup message: " + setupMsg

      # we're done
      moduleSelf.close()


  log "Spawning worker with data: " + JSON.stringify(data)
  worker = asyncrun workerModule

  # set up the worker
  worker.receive = (data) ->
    log "Received from worker: " + JSON.stringify(data)
  worker.error = (err) ->
    log "Error within worker: " + JSON.stringify(err)

  # send the message
  worker.send(data)

if typeof this.window == "undefined"
  this.run "run"
