should=require 'should'
async = require "async"
Statement = require "../models/statement"
http = require "request"

DatabaseHelper = require "../models/db-helper"

# To avoid annoying logging during tests
logfile = require('fs').createWriteStream 'extravagant-zombie.log'

url = "http://localhost:8081"
testState=
  title:"Apple sucks"

testState2=
  title:"Apple lags behind"

describe "Create new Statement", ->
  beforeEach (done) ->
    require('../server').start done
  it "should be successful.", (done) ->
    http
      method: "Post"
      url: url + "/v0/statement"
      json: true
      body: JSON.stringify(
        title: testState.title
      )
    , (err, res, body) ->
      return done err if err
      res.statusCode.should.be.equal 201
      body.should.be.a "object"
      body.should.have.property "id"
      testState.id = body.id
      done()

describe "Get Statement", ->
  beforeEach (done) ->
    server = require('../server').start done

  it "should be successful.", (done) ->
    http.get url + "/v0/statement/" + testState.id, (err, res, body) ->
      return done(err) if err
      res.statusCode.should.be.equal 200
      should.exist body
      obj = JSON.parse(body)
      obj.should.be.a "object"
      obj.should.have.property "id", testState.id
      obj.should.have.property "title", testState.title
      done()

describe "Points", ->
  beforeEach (done) ->
    server = require('../server').start done

  it "create should be successful.", (done) ->
    http
      method: "Post"
      url: url + "/v0/statement"
      json: true
      body: JSON.stringify(
        title: testState.title
      )
    , (err, res, body) ->
      return done err if err
      res.statusCode.should.be.equal 201, "first create"
      testState.id = body.id
      http
        method: "Post"
        url: url + "/v0/statement/"+body.id+"/side/"+"pro"
        json: true
        body: JSON.stringify(
          point: testState.title
        )
      , (err, res, body) ->
        return done err if err
        res.statusCode.should.be.equal 201, "second create"
        testState.id = body.id
        done()

describe "Points voting", ->
  beforeEach (done) ->
    server = require('../server').start (err)->
      return done err if err
      #create some test data
      http
        method: "Post"
        url: url + "/v0/statement"
        json: true
        body: JSON.stringify(
          title: testState.title
        )
      , (err, res, body) ->
        return done err if err
        res.statusCode.should.be.equal 201, "first create"
        testState.id = body.id
        http
          method: "Post"
          url: url + "/v0/statement/"+body.id+"/side/"+"pro"
          json: true
          body: JSON.stringify(
            point: testState2.title
          )
        , (err, res, body) ->
          return done err if err
          res.statusCode.should.be.equal 201, "second create"
          testState2.id = body.id
          console.log "created test data", testState,testState2
          done()

  it "vote up should be successful.", (done) ->
    http
      method: "Post"
      url: url + "/v0/statement/"+testState.id+"/side/pro/vote/"+testState2.id
      json: true
      body: JSON.stringify(
        vote: 1
      )
    , (err, res, body) ->
      return done err if err
      console.log "return value:", body, res.statusCode, testState.id
      res.statusCode.should.be.equal 200, "vote POST command should be sucessfull"
      body.votes.should.be.equal 1, "we should see a vote total of 1"
      done()

  it "vote down should be successful.", (done) ->
    http
      method: "Post"
      url: url + "/v0/statement/"+testState.id+"/side/pro/vote/"+testState2.id
      json: true
      body: JSON.stringify(
        vote: -1
      )
    , (err, res, body) ->
      return done err if err
      res.statusCode.should.be.equal 200, "vote POST command should be sucessfull"
      body.votes.should.be.equal -1, "we should see a vote total of -1"
      done()

  it "wrong vote should be unsuccessful.", (done) ->
    http
      method: "Post"
      url: url + "/v0/statement/"+testState.id+"/side/pro/vote/"+testState2.id
      json: true
      body: JSON.stringify(
        vote: 100
      )
    , (err, res, body) ->
      return done err if err
      res.statusCode.should.be.equal 400, "vote POST command should be unsucessfull"
      done()