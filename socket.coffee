class exports.Server

  constructor: (@port) ->

    User = require './models/user'

    express = require 'express'

    @user = new User 'test@gmail.com', 'test@gmail.com', 'test'
    @userTmpList = [ @user ]

    @conf = require './lib/conf'
    Security = require('./lib/security').Security
    @app = express.createServer()

    # convert existing coffeescript, styl, and less resources to js and css for the browser
    @app.use require('connect-assets')()

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
      @app.use(@app.router)

  start: (callback) ->
    User = require './models/user'
    Statement = require './models/statement'

    console.log 'Server starting'
    @app.listen @port
    console.log 'Server listening on port ' + @port

    @app.get '/', (req, res) ->
      res.render('home', {user: req.user, message: req.flash('error')})

    @app.get '/login', (req, res) ->
      res.render('login', {user: req.user, message: req.flash('error')})

    @app.get '/register', (req, res) ->
      res.render('register', {userData: {}, message: req.flash('error')})

    @app.get '/logout', (req, res) ->
      req.logOut()
      res.redirect('/')

    @app.post '/register', (req, res) ->
      newUserAttributes =
        username : req.body.username
        password : req.body.password
        email : req.body.email
        name : req.body.name
      User.validateUser newUserAttributes, (errors) ->
        if (errors.length)
          res.render('register', {errors: errors, userData: newUserAttributes})
        else
          User.create newUserAttributes, (err, user) ->
            if (err)
              res.render('register', {errors: errors, userData: newUserAttributes})
            else
              res.redirect('/login')

    @app.get '/test', (req, res) ->
      res.render 'test', {}

    @app.get '/statement/:id', (req, res) ->
      Statement.get req.params.id, (err,stmt) ->
        console.log "DB statement", stmt
        return res.render 'error', {error:err} if err
        stmt.get_representation 1, (err, representation) ->
          return res.render 'error', {error:err} if err
          console.log "Delivering Statement:\n", JSON.stringify(representation, null, 2)
          res.render 'statement', {statement: representation}

    @app.post '/statement/:id/add', (req, res) ->
      id=req.params.id
      side=req.body.side
      title=req.body.point
      Statement.get id, (err,stmt) ->
        return res.render 'error', {error:err} if err
        Statement.create {title: title}, (err,point)->
          point.argue stmt, side, (err)->
            return res.redirect('back');

    @app.get '/statement', (req, res) ->
      res.render 'new_statement'

    @app.post '/statement/new', (req, res) ->
      Statement.create {title: req.body.title}, (err,stmt) ->
        return res.render 'error', {error:err} if err
        return res.redirect("/statement/#{stmt.id}");

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
