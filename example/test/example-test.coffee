require 'should'
io = require('socket.io-client')

socketURL = 'http://0.0.0.0:8080'

options = 
  transports: ['websockets']
  'force new connection':true

describe 'Array', () ->
  describe '#indexOf()', () ->
    it 'should return -1 when the value is not present', () ->
      [1,2,3].indexOf(5).should.equal(-1);
      [1,2,3].indexOf(0).should.equal(-1);
    
  

describe 'test dummy server', () ->
  counter = -1
  it 'should check if data is 1', (done) ->
    connection = io.connect(socketURL, options)
    connection.on "count", (data) ->
      console.log("got here")
      console.log data.number
      counter = data.number
      counter.should.equal(1)
    connection.disconnect
    connection.count
