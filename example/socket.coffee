class exports.Server

  constructor: (@port) ->
    console.log "constructor started"
    express = require 'express'
    @express = express.createServer()
    @express.use express.bodyParser()
    @status = "initialized"
        
    @express.set('views', __dirname + '/views')
    @express.set('view engine', 'jade')
    @express.use(express.bodyParser())
    @express.use(express.methodOverride())
    @express.use(require('stylus').middleware({ src: __dirname + '/public' }))
    @express.use(@express.router)
    @express.use(express.static(__dirname + '/public'))

    #development
    @express.use(express.errorHandler({ dumpExceptions: true, showStack: true })) 

    #production
    #@express.use(express.errorHandler()) 

  start: (callback) ->
    console.log "Server starting"
    @express.listen @port
    console.log "Server listening on port " + @port    

    @express.get '/', (req, res) ->
      res.render 'index', {title: 'exampleNew'}

    @io = require('socket.io').listen @express
    count = 0
    @io.sockets.on "connection", (socket) ->
      count++
      console.log "user connected " + count
      socket.emit 'count', { number: count }
      socket.broadcast.emit 'count', { number: count }

      socket.on 'disconnect', () ->
        count--
        console.log "user disconnected "
        socket.broadcast.emit 'count', { number: count }
     callback()

  stop: (callback) ->
    @io.server.close()
    callback()

  
    
