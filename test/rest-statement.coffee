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
      testState.id = body.id
      http
        method: "Post"
        url: url + "/v0/statement/"+body.id+"/side/"+"pro"
        json: true
        body: JSON.stringify(
          title: testState.title
        )
      , (err, res, body) ->
        return done err if err
        res.statusCode.should.be.equal 201
        testState.id = body.id
        done()
