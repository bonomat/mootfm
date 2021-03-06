class exports.Security

    init: (app, cb) ->

      User = require "../models/user"
      @conf = require './conf'

      passport = require 'passport'

      app.use(passport.initialize())
      app.use(passport.session())

      LocalStrategy = require('passport-local').Strategy
      GoogleStrategy = require('passport-google-oauth').OAuth2Strategy
      FacebookStrategy = require("passport-facebook").Strategy
      TwitterStrategy = require('passport-twitter').Strategy

      #### TEST USER ####
      user_data=
        name: "Test User"
        email: "test@user.at"
        password: "password"
        username: "test@user.at"
      User.get_by_username "test@user.at" , (err, user) ->
        if (err)
          User.create user_data, (err,user)->
            console.log "ignored err" if err
            console.log "user saved" if !err

      passport.use new LocalStrategy (username, password, done) ->
        process.nextTick ->
          console.log "login called"
          User.get_by_username username , (err, user) ->
            if (err)
              return done(null, false, { message: 'Incorrect username or password!' })
            if (!user)
              return done(null, false, { message: 'Incorrect username or password!' })
            if ((user.password != password))
              return done(null, false, { message: 'Incorrect username or password!' })
            return done(null, user)

      passport.use new GoogleStrategy {clientID: @conf.google.clientId, clientSecret: @conf.google.clientSecret, callbackURL: @conf.google.callbackURL}, (accessToken, refreshToken, profile, done) ->
        process.nextTick () ->
          User.find_or_create_google_user profile, (error, user) ->
            return done(error, user)

      passport.use new FacebookStrategy {clientID: @conf.facebook.appId, clientSecret: @conf.facebook.appSecret, callbackURL: @conf.facebook.callbackURL}, (accessToken, refreshToken, profile, done) ->
        process.nextTick () ->
          User.find_or_create_facebook_user profile, (error, user) ->
            return done(error, user)

      passport.use new TwitterStrategy {consumerKey: @conf.twitter.consumerKey, consumerSecret: @conf.twitter.consumerSecret, callbackURL: @conf.twitter.callbackURL}, (token, tokenSecret, profile, done) ->
        process.nextTick () ->
          User.find_or_create_twitter_user profile, (error, user) ->
            return done(error, user)

      passport.serializeUser (user, done) ->
        done(null, user.username)

      passport.deserializeUser (username, done) ->
        User.get_by_username username, (err, user) ->
          done(err, user)

      app.post '/login', passport.authenticate('local', { successRedirect: '/loggedin',  failureRedirect: '/login', failureFlash: true })

      app.get "/auth/google", passport.authenticate("google", { scope: @conf.google.scope }), (req, res) ->  # this function will never be called, it is just needed for passportjs

      app.get '/auth/facebook', passport.authenticate('facebook'), (req, res) ->  # this function will never be called, it is just needed for passportjs

      app.get "/auth/twitter", passport.authenticate("twitter"), (req, res) ->  # this function will never be called, it is just needed for passportjs

      app.get @conf.google.callbackURL, passport.authenticate("google", failureRedirect: "/fail"), (req, res) ->
        res.redirect "/loggedin"

      app.get @conf.facebook.callbackURL, passport.authenticate("facebook", failureRedirect: "/fail"), (req, res) ->
        res.redirect "/loggedin"

      app.get @conf.twitter.callbackURL, passport.authenticate("twitter", failureRedirect: "/fail"), (req, res) ->
        res.redirect "/loggedin"

      cb null, passport

