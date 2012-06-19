class exports.Security
  
    init: (app, cb) ->

      User = require "../models/user"
      @conf = require './conf'

      passport = require 'passport'

      app.use(passport.initialize())
      app.use(passport.session())

      LocalStrategy = require('passport-local').Strategy
      GoogleStrategy = require('passport-google-oauth').OAuth2Strategy

      passport.use new LocalStrategy (username, password, done) ->
        process.nextTick ->
          User.get_by_username username , (err, user) ->
            if (err)
              return done(null, false, { message: 'Incorrect username or password!' })
            if (!user) 
              return done(null, false, { message: 'Unknown user' })
            if (!user.password == password) 
              return done(null, false, { message: 'Invalid password' })  
            return done(null, user)

      passport.use new GoogleStrategy {clientID: @conf.google.clientId, clientSecret: @conf.google.clientSecret, callbackURL: @conf.google.callbackURL}, (accessToken, refreshToken, profile, done) ->
        process.nextTick () ->
          User.find_or_create_google_user profile, (error, user) ->
            return done(error, user)


      passport.serializeUser (user, done) ->
        done(null, user.username)

      passport.deserializeUser (username, done) ->
        User.get_by_username username, (err, user) ->
          done(err, user)

      app.post '/login',
        passport.authenticate('local', { successRedirect: '/',  failureRedirect: '/login', failureFlash: true })

      app.get "/auth/google", 
        passport.authenticate("google", 
          { scope: @conf.google.scope }
        ), (req, res) ->
          # this function will never be called, it is just needed for passportjs

      app.get @conf.google.callbackURL, passport.authenticate("google", failureRedirect: "/fail"), (req, res) ->
          res.redirect "/"

      cb null, passport
  
