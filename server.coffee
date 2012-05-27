express = require 'express'

Server = require('./socket').Server

server = new Server process.env.PORT || 8081

if not module.parent
  #starting server
  server.start (done) ->
    console.log "Server successfull started"
