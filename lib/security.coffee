class exports.Security
  
    init: (cb) ->
      @everyauth = require 'everyauth'
      User = require '../models/user'
      @conf = require './conf'
      @Promise = @everyauth.Promise
      @everyauth.debug = true
      
      @user = {}
      @everyauth
        .everymodule
        .findUserById (userId, callback) =>
          console.log "accessing find user by id: " + userId
          callback null, @user      

      @everyauth
      .google
      .appId(@conf.google.clientId)
      .appSecret(@conf.google.clientSecret)
      .scope('https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email')
      .findOrCreateUser (sess, accessToken, extra, googleUser) =>
        googleUser.refreshToken = extra.refresh_token
        googleUser.expiresIn = extra.expires_in
        user = new User googleUser.id, googleUser.email, null        
        console.log "retrieved user " + user.id + " mail: " + user.email
        @user = user
        return user
      .redirectPath '/'

      @everyauth
        .twitter
        .consumerKey(@conf.twit.consumerKey)
        .consumerSecret(@conf.twit.consumerSecret)
        .findOrCreateUser (sess, accessToken, accessSecret, twitUser) ->
          console.log "retrieved twitter info"
          console.log twitUser
          user = new User twitUser.name, twitUser.screen_name, null
          @user = user
          return user
        .redirectPath '/'

      @everyauth
        .facebook
        .appId(@conf.fb.appId)
        .appSecret(@conf.fb.appSecret)
        .findOrCreateUser (session, accessToken, accessTokenExtra, fbUserMetadata) ->
          console.log "retrieved facebook info"
          console.log fbUserMetadata
          user = new User fbUserMetadata.username, fbUserMetadata.username, fbUserMetadata.username
          @user = user
          return user
        .redirectPath '/'

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
        )
        .authenticate((login, password) =>
          console.log "authenticating with " + login + " pw: " + password
          errors = []
          errors.push 'Missing login'  unless login
          errors.push 'Missing password'  unless password
          errors.push 'Login failed, user not defined' unless @user
          errors.push 'Login failed, wrong password' if @user.password isnt password
          return errors  if errors.length
          return @user
        )
        .getRegisterPath('/register')
        .postRegisterPath('/register')
        .registerView('register.jade')
        .registerLocals (req, res, done) ->
          setTimeout (->
            done null,
              title: 'mootFM'
          ), 200
        .validateRegistration (newUserAttrs, errors) =>
          login = newUserAttrs.login
          #TODO check if user is in DB
    #      @db.get_user_by_id login, (err, get_user)->
    #        errors.push 'Login already taken'  if !err
          return errors
        .registerUser (newUserAttrs) =>
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
          @user = new_user
          return @user
        .loginSuccessRedirect('/')
        .registerSuccessRedirect('/login')
        # TODO get user from memory or d
      cb null, @everyauth
  
