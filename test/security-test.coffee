should=require 'should'
async = require "async"
Statement = require "../models/statement"
http = require "request"
User = require "../models/user"

DatabaseHelper = require "../models/db-helper"

# To avoid annoying logging during tests
logfile = require('fs').createWriteStream 'extravagant-zombie.log'

url = "http://localhost:8081"
user_data=
  name: "Test User"
  email: "test@user.at"
  password: "password"
  username: "test@user.at"
  
describe "Login Test", ->
  before (done) ->
    User.get_by_username user_data.email , (err, user) ->
      if (err)
        User.create user_data, (err,user)->
          console.log "ignored err" if err
          console.log "user saved" if !err
          require('../server').start done
      else require('../server').start done
   
  it "login with username and password.", (done) ->
    http
      method: "Post"
      url: url + "/login"
      followRedirect:false
      form: 
        username: user_data.email
        password: user_data.password
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

  it "login with illegal username and password.", (done) ->
    http
      method: "Post"
      url: url + "/login"
      followRedirect:false
      form: 
        username: 'illegalUsername'
        password: 'password'
    , (err, res, body) ->
      return done err if err
      res.headers.location.should.be.equal "/login"
      res.statusCode.should.be.equal 302
      http
        method: "GET"
        url: url + res.headers.location
      , (err, res, body) ->
        res.body.search("Incorrect username or password!").should.not.be.equal -1
        done()
        
  it "login with username and wrong password.", (done) ->
    http
      method: "Post"
      url: url + "/login"
      followRedirect:false
      form: 
        username: 'test@user.at'
        password: 'completelyWrongPassword'
    , (err, res, body) ->
      return done err if err
      res.headers.location.should.be.equal "/login"
      res.statusCode.should.be.equal 302
      http
        method: "GET"
        url: url + res.headers.location
      , (err, res, body) ->
        res.body.search("Incorrect username or password!").should.not.be.equal -1
        done()
        
        
        