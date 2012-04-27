require 'should'
io = require('socket.io-client')
server = require('../test-server')

socketURL = 'http://0.0.0.0:8080'

options = 
  transports: ['websockets']
  'force new connection':true

describe "Dummy Test Server", ->
  before (done) ->
    done
  after (done) ->
    done
  it "data should be 1", (done) ->
    client1 = io.connect(socketURL, options)
    client1.on "count", (data) ->
      data.number.should.equal(1)
