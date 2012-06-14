class exports.Server

  constructor: (@port) ->
    User = require './models/user'

    express = require 'express'

    @user = new User 'test@gmail.com', 'test@gmail.com', 'test'
    @userTmpList = [ @user ]
    
    @conf = require './lib/conf'
    Security = require('./lib/security').Security
    @app = express.createServer()    
    
    @app.use express.bodyParser()

    @app.set('views', __dirname + '/views')
    @app.set('view engine', 'jade')
    @app.use(express.bodyParser())
    @app.use(express.methodOverride())
    @app.use(require('stylus').middleware({ src: __dirname + '/public' }))
    @app.use(express.static(__dirname + '/public'))
    @app.use(express.cookieParser())
    @app.use(express.session { secret :'test'})

    #development
    @app.use(express.errorHandler({
      dumpExceptions: true, showStack: true
    }))

    #production
    #@app.use(express.errorHandler())    
    security = new Security
    security.init (error, callback) =>
      @app.use(callback.middleware())    
      @app.use(@app.router)  
      callback.helpExpress(@app)
      callback = callback


  start: (callback) ->
    console.log 'Server starting'
    @app.listen @port
    console.log 'Server listening on port ' + @port

    @app.get '/', (req, res) ->
      console.log req.user
      console.log req.session
      res.render('home')

    @io = require('socket.io').listen @app
    count = 0
    @io.sockets.on 'connection', (socket) =>
      count++
      console.log 'user connected ' + count
      socket.emit 'count', { number: count }
      socket.broadcast.emit 'count', { number: count }

      socket.on 'disconnect', () =>
        count--
        console.log 'user disconnected '
        socket.broadcast.emit 'count', { number: count }
    callback()

  stop: (callback) ->
    @io.server.close()
    callback()
