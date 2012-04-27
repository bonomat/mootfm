express = require('express')
io = require('socket.io')
testserver = require('./test-server')

app = module.exports = express.createServer() 

app.configure () -> 
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(require('stylus').middleware({ src: __dirname + '/public' }))
  app.use(app.router)
  app.use(express.static(__dirname + '/public'))

app.configure 'development', () -> 
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true })) 

app.configure 'production', () -> 
  app.use(express.errorHandler()) 

app.get '/', (req, res) ->
  res.render 'index', {title: 'example'}

if not module.parent
  console.log "Starting io socket"
  testserver.start app
  console.log "Starting io app listener"
  app.listen 8080
  console.log "Express server listening on port %d", app.address().port

