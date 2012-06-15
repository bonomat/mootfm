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
    security.init @app, (error, passport) =>
      @app.use(passport.initialize())
      @app.use(passport.session())
      @app.use(@app.router)


  start: (callback) ->
    User = require './models/user'
    console.log 'Server starting'
    @app.listen @port
    console.log 'Server listening on port ' + @port

    @app.get '/', (req, res) ->
      res.render('home')

    @app.get '/login', (req, res) ->
      res.render('login', {user: req.user, message: req.flash('error')})

    @app.get '/register', (req, res) ->
      res.render('register', {userData: {}, message: req.flash('error')})

    @app.post '/register', (req, res) ->
      newUserAttributes = 
        username : req.body.username
        password : req.body.password
        email : req.body.email
        name : req.body.name
      errors = User.validateUser newUserAttributes
      if (errors.length) 
        res.render('register', {errors: errors, userData: newUserAttributes}) 
      else       
        res.redirect('/account')

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
