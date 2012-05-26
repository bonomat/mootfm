class exports.Server

  constructor: (@port) ->
    User = require './models/user'
    DAONeo4j = require './models/dao-neo4j'
    
    @db = new DAONeo4j 'http://localhost:7474'
    express = require 'express'
    @conf = require './conf'    
    @app = express.createServer()
    @app.use express.bodyParser()

    @status = 'initialized'
        
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
    @everyauth.debug = true

    #production
    #@app.use(express.errorHandler())
    
    @everyauth = require 'everyauth'
    @Promise = @everyauth.Promise
    @everyauth.password.loginWith 'email'
   
###################every auth settings#################
    @everyauth
      .google
      .appId(@conf.google.clientId)
      .appSecret(@conf.google.clientSecret)
      .scope('https://www.googleapis.com/auth/userinfo.profile https://www.google.com/m8/feeds/')
      .findOrCreateUser((sess, accessToken, extra, googleUser) ->
        googleUser.refreshToken = extra.refresh_token
        googleUser.expiresIn = extra.expires_in
        usersByGoogleId[googleUser.id] or (usersByGoogleId[googleUser.id] = addUser('google', googleUser))
      ).redirectPath '/'

    exampleUser = new User 'test', 'test@gmail.com', 'test'
    @userTmpList = [ exampleUser ]
    @user = exampleUser    

    @everyauth
      .password
      .loginWith('login')
      .getLoginPath('/login')
      .postLoginPath('/login')
      .loginView('login.jade')
      .loginLocals((req, res, done) ->
        setTimeout (->
          done null,
            title: 'Async login'
        ), 200
    ).authenticate((login, password) =>
      errors = []
      errors.push 'Missing login'  unless login
      errors.push 'Missing password'  unless password
      return errors  if errors.length
      return [ 'Login failed, user not defined' ]  unless @user
      return [ 'Login failed, wrong password' ]  if @user.password isnt password
      @user
    ).getRegisterPath('/register').postRegisterPath('/register').registerView('register.jade').registerLocals((req, res, done) ->
      setTimeout (->
        done null,
          title: 'Async Register'
      ), 200
    ).extractExtraRegistrationParams((req) ->
      email: req.body.email
    ).validateRegistration((newUserAttrs, errors) =>
      login = newUserAttrs.login
      #TODO check if user is in DB      
#      @db.get_user_by_id login, (err, get_user)->
#        errors.push 'Login already taken'  if !err     
      errors   
    ).registerUser((newUserAttrs) =>
      login = newUserAttrs.login
      password = newUserAttrs.password
      console.log "user name is " + login
      console.log "user password is " + password
      # TODO verify if login equals emailadress
      new_user = new User login, login, password
      
      @user = new_user
      @db.new_user login, (err,new_user)->        
        errors = []
        errors.push 'An error has occured' if err
        return errors  if errors.length
        @userTmpList.push(new_user)
      return @user
    ).loginSuccessRedirect('/').registerSuccessRedirect '/'

    # get user from memory or db
    @everyauth.everymodule.findUserById (userId, callback) ->
      console.log "accessing find user by id: " + userId 
      callback null, @user




    @app.use(@everyauth.middleware())
    
    @everyauth.helpExpress(@app)    

  start: (callback) ->
    console.log 'Server starting'
    @app.listen @port
    console.log 'Server listening on port ' + @port

    @app.get '/', (req, res) ->
      res.render('home', { users: JSON.stringify(@usersByLogin, null, 2) } )



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
