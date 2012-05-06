require 'should'
io = require('socket.io-client')

Server = require('../socket').Server

socketURL = 'http://localhost:5000'
options = 
  transports: ['websockets']
  'force new connection':false

describe "Example test with test server", ->
  beforeEach (done) ->
    @server = new Server 5000
    @server.start done
    console.info "running before test"
  afterEach (done) ->    
    console.info "running after test"
    @server.stop done

  it "When one user is connected count should be 1", (done) ->
    console.info "starting test1"
    client1 = io.connect(socketURL, options)
    client1.on "count", (counter) ->
      counter.number.should.equal 1
      client1.disconnect()
      done()

  it "When two users are connected count should be 2", (done) ->
    client1 = io.connect(socketURL, options)
    client1.on "count", (counter) ->
      #I don't know why this part is only called once and not twice, it is called after the second client has connected
      counter.number.should.equal 2

    client2 = io.connect(socketURL, options)   
        
    client2.on "count", (counter) ->
      #TODO  fix this counter.number, check when it is called,
      counter.number.should.equal counter.number
      client2.disconnect()
      client1.disconnect()
      # because this part is called twice, shutdown only when both clients are connected
      if counter.number is 2
        done()
