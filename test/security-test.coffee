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
  beforeEach (done) ->
    User.get_by_username "test@user.at" , (err, user) ->
      if (err)
        User.create user_data, (err, user)->
          require('../server').start done
      else
        require('../server').start done
  it "should be successful.", (done) ->
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
        
        
        