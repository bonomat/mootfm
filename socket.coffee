class exports.Server

  constructor: (@port) ->
    express = require 'express'
    @conf = require './conf'    
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
    @express.use(express.cookieParser())
    @express.use(express.session { secret:'asfgr234rfs'})

    #development
    @express.use(express.errorHandler({
      dumpExceptions: true, showStack: true
    }))

    #production
    #@express.use(express.errorHandler())
    
    @everyauth = require 'everyauth'
    @everyauth
      .google
      .appId(@conf.google.clientId)
      .appSecret(@conf.google.clientSecret)
      .scope("https://www.googleapis.com/auth/userinfo.profile https://www.google.com/m8/feeds/")
      .findOrCreateUser((sess, accessToken, extra, googleUser) ->
        googleUser.refreshToken = extra.refresh_token
        googleUser.expiresIn = extra.expires_in
        usersByGoogleId[googleUser.id] or (usersByGoogleId[googleUser.id] = addUser("google", googleUser))
      ).redirectPath "/"


    @express.use(@everyauth.middleware())
    @everyauth.helpExpress(@express)    

  start: (callback) ->
    console.log "Server starting"
    @express.listen @port
    console.log "Server listening on port " + @port

    @express.get '/', (req, res) ->
      if req.session.auth
        console.log req.session.auth.github
        user = req.session.auth.github.user.name
        console.log "user:"+user
        res.render('index', {
          title: user
          usr: user
          layout:false
        })


    @io = require('socket.io').listen @express
    count = 0
    @io.sockets.on "connection", (socket) =>
      count++
      console.log "user connected " + count
      socket.emit 'count', { number: count }
      socket.broadcast.emit 'count', { number: count }

      socket.on 'disconnect', () =>
        count--
        console.log "user disconnected "
        socket.broadcast.emit 'count', { number: count }
    callback()

  stop: (callback) ->
    @io.server.close()
    callback()
