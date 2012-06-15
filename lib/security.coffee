class exports.Security
  
    init: (app, cb) ->

      User = require "../models/user"
      @conf = require './conf'

      passport = require 'passport'
      LocalStrategy = require('passport-local').Strategy
      
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

      passport.serializeUser (user, done) ->
        done(null, user.username)

      passport.deserializeUser (username, done) ->
        User.get_by_username username, (err, user) ->
          done(err, user)

      app.post '/login',
        passport.authenticate('local', { successRedirect: '/',  failureRedirect: '/login', failureFlash: true })

      cb null, passport
  
