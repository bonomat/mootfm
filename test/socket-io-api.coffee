should=require 'should'
async = require "async"
io = require('socket.io-client')

# To avoid annoying logging during tests
logfile = require('fs').createWriteStream 'extravagant-zombie.log'

testState=
  title:"Apple sucks"

testState2=
  title:"Apple lags behind"

url = "http://localhost:8081"
options =
  transports: ['websockets']
  'force new connection':true

describe "Socket IO - Create new Statement", ->
  beforeEach (done) ->
    require('../server').start done

  it "should be successful.", (done) ->
    client1 = io.connect(url, options)
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
