io = null

module.exports = 
  start: (port, cb) ->
    io = require('socket.io').listen port, cb
    count = 0
    test = 'Hi there, you rock'  
  
    io.sockets.on 'connection', (socket) ->
      count++
 
    io.sockets.emit 'count', { number: count }

    io.sockets.emit 'test', { number: count }

    setInterval(() ->
      io.sockets.emit 'count', { number: count }
      , 12000)

    setInterval(() ->
      io.sockets.emit 'test', { text: test }
    , 10000)

    io.sockets.on 'disconnect', () ->
      count--
      io.sockets.emit 'count', { number: count }
  stop: (cb) ->
    io.server.close()
    cb()

