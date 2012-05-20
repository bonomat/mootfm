require 'should'
io = require('socket.io-client')

Server = require('../socket').Server

socketURL = 'http://localhost:5000'
options = 
  transports: ['websockets']
  'force new connection':true 

describe "Example test with test server", ->
  beforeEach (done) ->
    @server = new Server 5000
    @server.start done
  afterEach (done) ->    
    @server.stop done

  it "When one user is connected count should be 1", (done) ->
    client1 = io.connect(socketURL, options)
    client1.on "count", (counter) ->
      counter.number.should.equal 1
      client1.disconnect()
      done()

