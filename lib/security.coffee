class exports.Security
  
    init: (cb) ->
      @everyauth = require 'everyauth'
      User = require "../models/user"
      @conf = require './conf'
      Promise = @everyauth.Promise
      @everyauth.debug = true
      console.log Promise

      @everyauth
        .everymodule
        .findUserById (userId, callback) =>
          console.log "accessing find user by id: " + userId
          @user = {}          
          User.get userId, (err,get_user)=>
            #TODO redirect to user not found
            console.log err if err
            @user = get_user
          callback null, @user

      @everyauth
      .google
      .appId(@conf.google.clientId)
      .appSecret(@conf.google.clientSecret)
      .scope('https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email')
      .findOrCreateUser (sess, accessToken, extra, googleUser, data) =>
        googleUser.refreshToken = extra.refresh_token
        googleUser.expiresIn = extra.expires_in
        #Promise = @everyauth.Promise
        #console.log Promise
        #console.log "----"
        #promise = Promise()
        #console.log promise
        #console.log "----"
        @user = {}
        User.find_by_google_id googleUser.id, (err, user) ->
          if err
            sess.user_exists = false
            @user = null
          else
            @user = user
          #sess.user_data = user_data if err
        return @user
      .sendResponse  (res, data) =>
        user_exists = data.session.user_exists
        if (! user_exists)
          return res.redirect('/register')
        res.redirect('/')

      @everyauth
        .twitter
        .consumerKey(@conf.twit.consumerKey)
        .consumerSecret(@conf.twit.consumerSecret)
        .findOrCreateUser (sess, accessToken, accessSecret, twitUser) ->
          @user = {}
          user_data=
            username: twitUser.name
            email: "TODO"
            password: "TODO"
          User.create user_data, (err,user)=>
            return err if err      
            @user = user
          return @user
        .redirectPath '/'

      @everyauth
        .facebook
        .appId(@conf.fb.appId)
        .appSecret(@conf.fb.appSecret)
        .findOrCreateUser (session, accessToken, accessTokenExtra, fbUserMetadata) ->
          console.log "retrieved facebook info"
          console.log fbUserMetadata
          @user = {}
          user_data=
            username: fbUserMetadata.username
            email: "TODO"
            password: "TODO"
          User.create user_data, (err,user)=>
            return err if err      
            @user = user
          return @user
        .redirectPath '/'

      @everyauth
        .password
        .loginHumanName('username')
        .loginKey('username')
        .loginWith('login')
        .getLoginPath('/login')
        .postLoginPath('/login')
        .loginView('login.jade')
        .loginLocals (req, res, done) ->
          setTimeout (->
            done null,
              title: 'Async login'
          ), 200
        .extractExtraRegistrationParams (req) ->
          return {
            email: req.body.email
            google_id: req.body.google_id
            facebook_id: req.body.facebook_id
            twitter_id: req.body.twitter_id
          }
        .displayRegister (req, res, data) ->
          userParams = {}
          ############## extract google data ###########
          if req.session.auth.google
            user = req.session.auth.google.user
            userParams.google_id = user.id
            userParams.email = user.email
          console.log "passing following data to registration form "
          console.log userParams
          res.render('register', { userParams: userParams })
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
          console.log "got following attributes"
          console.log newUserAttrs
          login = newUserAttrs.login
          password = newUserAttrs.password
          @user = {}
          user_data=
            username: "TODO"
            email: login
            password: password
          User.create user_data, (err,user)=>
            return err if err      
            @user = user
          return @user
        .loginSuccessRedirect('/')
        .registerSuccessRedirect('/login')
      cb null, @everyauth
  
