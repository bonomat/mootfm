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
  side: "pro"


url = "http://localhost:8081"
options =
  transports: ['websockets']
  'force new connection':true

create_user = (callback)->
  User.get_by_username user_data.email , (err, user) ->
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
    res.headers.location.should.be.equal "/loggedin", "wrong redirect, probably because of failed login"
    res.statusCode.should.be.equal 302
    console.log body
    http
      method: "GET"
      url: url + "/statement"
    , (err, res, body) ->      
      options.query= res.request.headers.cookie
      callback()

describe "Socket IO", ->
  beforeEach (done) ->
    require('../server').start (err)->
      create_user ->
        login done

  it "post should be successful.", (done) ->
    client1 = io.connect(url, options)
    client1.emit "post",testState
    client1.once "statement", (statements) ->
      statements[0].title.should.equal(testState.title,"should receive same statement title on create");
      #state.should.have.property('user')
      #state.user.should.have.property('id')
      #state.user.should.have.property('name')
      #state.user.should.have.property('picture_url')
      client1.disconnect()
      done()
  it "get should be successful.", (done) ->
    client1 = io.connect(url, options)
    client1.emit "post",testState
    client1.once "statement", (statements) ->
      client1.emit "get",statements[0].id
      client1.once "statement", (statements) ->
        statements.should.be.an.instanceOf(Array)
        statements.length.should.be.equal 1, "wrong number of statements found"
        statements[0].title.should.equal testState.title,"should receive same statement title on create"
        #state.should.have.property('user')
        #state.user.should.have.property('id')
        #state.user.should.have.property('name')
        #state.user.should.have.property('picture_url')
        client1.disconnect()
        done()
  it "argue should be successful.", (done) ->
    ids= []
    client1 = io.connect(url, options)
    client1.emit "post",testState
    client1.once "statement", (statements) ->
      ids[0]=statements[0].id
      testState2.parent= statements[0].id
      client1.emit "post",testState2
      client1.once "statement", (statements) ->
        statements[0].parent.should.be.equal testState2.parent, "wrong parent found"
        statements[0].side.should.be.equal testState2.side, "wrong side found"
        statements[0].vote.should.be.equal 0, "wrong vote found"
        ids[1]=statements[0].id
        client1.emit "get",ids[0]
        client1.once "statement", (statements) ->
          statements.should.be.an.instanceOf(Array)
          statements.length.should.be.equal 2, "wrong number of statements found"
          
          #state.should.have.property('user')
          #state.user.should.have.property('id')
          #state.user.should.have.property('name')
          #state.user.should.have.property('picture_url')
          client1.disconnect()
          done()

  it "vote should be successful.", (done) ->
    ids= []
    client1 = io.connect(url, options)
    client1.emit "post",testState
    client1.once "statement", (statements) ->
      ids[0]=statements[0].id
      testState2.parent= statements[0].id
      client1.emit "post",testState2
      client1.once "statement", (statements) ->
        ids[1]=statements[0].id
        client1.emit "get",ids[0]
        client1.once "statement", (statements) ->
          statements.should.be.an.instanceOf(Array)
          statements.length.should.be.equal 2, "wrong number of statements found"
          for stmt in statements
            if stmt.id==ids[1]
              point=stmt
              stmt.side.should.be.equal testState2.side, "wrong side found for point"
              stmt.vote.should.be.equal 0, "wrong number of votes for point"
          client1.emit "vote",point,1
          client1.once "statement", (statements) ->
            statements.should.be.an.instanceOf(Array)
            statements.length.should.be.equal 1, "wrong number of statements found"
            statements[0].vote.should.be.equal 1, "wrong number of votes for point"
            #state.should.have.property('user')
            #state.user.should.have.property('id')
            #state.user.should.have.property('name')
            #state.user.should.have.property('picture_url')
            client1.disconnect()
            done()

  it "register should be successful.", (done) ->
    ids= []
    #fix multiple logins
    false.should.be.ok "fix multiple logings"
    client1 = io.connect(url, options)
    client2 = io.connect(url, options)
    client1.emit "post",testState
    async.waterfall [
      (callback)->
        client1.once "statement", (stmts)->
          callback null, stmts
      (stmts, callback) ->
        callback null, stmts[0].id
      (id, callback) ->
        client1.emit "register", id
        point=
          parent: id
          cid:"c1"
          title: "new pro arg"
          side: "pro"
        client2.emit "post",point
        client1.once "statement", (stmts)->
          callback null, stmts,id
      (stmts,id, callback) ->
        stmts.should.be.an.instanceOf(Array)
        stmts.length.should.be.equal 1, "wrong number of statements found"
        stmts[0].vote.should.be.equal 0, "wrong number of votes for point"
        stmts[0].should.have.property('id')
        stmts[0].should.not.have.property('cid')
        stmts[0].parent.should.be.equal id, "wrong parent for point"
        stmts[0].side.should.be.equal "pro", "wrong side for point"
        callback()
    ], (a,b,c)->
      console.log a,b,c
      done(a,b,c)

  it "register 2 people should be successful.", (done) ->
    ids= []
    #fix multiple logins
    false.should.be.ok "fix multiple logings"
    client1 = io.connect(url, options)
    client2 = io.connect(url, options)
    client3 = io.connect(url, options)
    client1.emit "post",testState
    async.waterfall [
      (callback)->
        client1.once "statement", (stmts)->
          callback null, stmts
      (stmts, callback) ->
        callback null, stmts[0].id
      (id, callback) ->
        client1.emit "register", id
        client2.emit "register", id
        point=
          parent: id
          cid:"c1"
          title: "new pro arg"
          side: "pro"
        client3.emit "post",point
        callback()
    ], (err)->
      return done(err) if err
          
    async.forEach [client1,client2], (client,callback)=>
      client.once "statement", (stmts)->
        console.log "received:", stmts
        stmts.should.be.an.instanceOf(Array)
        stmts.length.should.be.equal 1, "wrong number of statements found"
        stmts[0].should.have.property 'vote',0, "wrong number of votes for point"
        stmts[0].should.have.property 'id'
        stmts[0].should.not.have.property 'cid'
        stmts[0].should.have.property 'parent',id, "wrong parent for point"
        stmts[0].should.have.property 'side',"pro", "wrong side for point"
        callback()
    , done