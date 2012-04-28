require 'should'
io = require('socket.io-client')
server = require('../test-server')

socketURL = 'http://0.0.0.0:5000'

options = 
  transports: ['websockets']
  'force new connection':true

describe "Example test with one client", ->
  before (done) ->
    server.start 5000, done
  after (done) ->
    server.stop done

  it "When one user is connected count should be 1", (done) ->
    client1 = io.connect(socketURL, options)

    client1.on "count", (counter) ->
      counter.number.should.equal 1
      client1.disconnect()
      done()

describe "Example test with two clients", ->
  before (done) ->
    server.start 5000, done
  after (done) ->
    server.stop done

  it "When two users are connected count should be 2", (done) ->
    client1 = io.connect(socketURL, options)
    client1.on "count", (counter) ->
      console.log "local counter is : " + counter.number
      counter.number.should.equal 2
    
    client2 = io.connect(socketURL, options)
    client2.on "count", (counter) ->
      console.log "local counter is now: " + counter.number
      counter.number.should.equal counter.number
      client2.disconnect()
      client1.disconnect()
      if counter.number is 2
        done()
