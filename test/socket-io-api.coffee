should = require 'should'
async = require "async"
io = require 'socket.io-client'

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

testState=
  title:"Apple sucks"

testState2=
  title:"Apple lags behind"

url = "http://localhost:8081"
options =
  transports: ['websockets']
  'force new connection':true

create_user = (callback)->
  User.get_by_username "test@user.at" , (err, user) ->
    if (err)
      User.create user_data, callback
    else
      callback()

login = (callback)->
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
      console.log "cookie",res.request.headers.cookie
      console.log "logged in"
      options.query=
        res.request.headers.cookie
      callback()

describe "Socket IO - Create new Statement", ->
  beforeEach (done) ->
    require('../server').start (err)->
      create_user( ->
        login done
      )

  it "should be successful.", (done) ->
    console.log "starting"
    #io.set "authorization", (data, accept) =>
    #  console.log "authorization called"

    client1 = io.connect(url, options)
    console.log "connected"
    #io.on 'connect', ->
    #  console.info 'successfully established a working connection \o/'

    #client1.addEvent "connect", ->
    #  # Send PHP session ID, which will be used to authenticate
    #  sessid = readCookie("sessionID");
    #  this.send("{'action':'authenticate','sessionid':'"+sessid+"'}");

    client1.emit "statement",testState
    client1.on "confirm", (state) ->
      console.log "received",state
      state.title.should.equal(testState.title,"should receive same statement title on create");
      #state.should.have.property('user')
      #state.user.should.have.property('id')
      #state.user.should.have.property('name')
      #state.user.should.have.property('picture_url')
      client1.disconnect()
      done()
