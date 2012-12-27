should=require 'should'
async = require "async"
Statement = require "../models/statement"
http = require "request"
User = require "../models/user"

DatabaseHelper = require "../models/db-helper"

# To avoid annoying logging during tests
logfile = require('fs').createWriteStream 'extravagant-zombie.log'

url = "http://localhost:8081"

describe "Login Test", ->
  beforeEach (done) ->
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
          
          
    require('../server').start done
  it "should be successful.", (done) ->
    http
      method: "Post"
      url: url + "/login"
      followRedirect:false
      form: 
        username: 'test@user.at'
        password: 'password'
    , (err, res, body) ->
      return done err if err
      res.headers.location.should.be.equal "/success"
      res.statusCode.should.be.equal 302
      http
        method: "GET"
        url: url + res.headers.location
      , (err, res, body) ->
        res.body.search("test@user.at").should.not.be.equal -1
        done()