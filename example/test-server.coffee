io = null
clients = {}
count = 0

module.exports = 
  start: (port, cb) ->
    io = require("socket.io").listen port, cb
    io.sockets.on "connection", (socket) ->
      count++
      
      io.sockets.emit 'count', { number: count }
      socket.on 'disconnect', () ->
        count--
        io.sockets.emit 'count', { number: count }

      socket.on 'disconnect', () ->
        count--
        io.sockets.emit 'count', { number: count }

      setInterval(() ->
        socket.emit 'count', { number: count }, 2000)




  stop: (cb) ->
    io.server.close()
    cb()
