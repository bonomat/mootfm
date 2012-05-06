class exports.Server

  constructor: (@port) ->
    console.log "constructor started"
    express = require 'express'
    @express = express.createServer()
    @io = require('socket.io').listen(@express)
    @express.use express.bodyParser()
    @status = "initialized"
        
    @express.set('views', __dirname + '/views')
    @express.set('view engine', 'jade')
    @express.use(express.bodyParser())
    @express.use(express.methodOverride())
    @express.use(require('stylus').middleware({ src: __dirname + '/public' }))
    @express.use(@express.router)
    @express.use(express.static(__dirname + '/public'))

    #@express.configure 'development', () -> 
    @express.use(express.errorHandler({ dumpExceptions: true, showStack: true })) 

    #@express.configure 'production', () -> 
    #@express.use(express.errorHandler()) 

  start: ->
    console.log "Server starting"
    @express.listen @port
    console.log "Server listening on port " + @port
    @status = "running"
    @express.get '/', (req, res) ->
      res.render 'index', {title: 'exampleNew'} 
    @io.sockets.on "connection", (socket) ->
      count++
      
      @io.sockets.emit 'count', { number: count }
      socket.on 'disconnect', () ->
        count--
        io.sockets.emit 'count', { number: count }

      socket.on 'disconnect', () ->
        count--
        io.sockets.emit 'count', { number: count }

      setInterval(() ->
        socket.emit 'count', { number: count }, 2000)

  stop: (cb) ->
    @io.server.close()
    cb()

  
    
