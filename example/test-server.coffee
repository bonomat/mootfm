io = null
clients = {}
count = 0

module.exports = 
  start: (cb) ->
    io = require("socket.io").listen 5000, cb
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
