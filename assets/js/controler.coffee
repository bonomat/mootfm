# require dependency
views = require "./views.coffee"
models = require "./models.coffee"

io = require('socket.io-client')
url = "http://localhost:8081"
options =
  transports: ['websockets']

#### button logic
openWindow = (url) ->
  created_window = window.open(url, 'login window', 'height=200','width=200','modal=yes','alwaysRaised=yes')
  $(created_window).unload ->
    router.connect_socket_io()

PopupUnload = (wnd) ->
  setTimeout (-> # setTimeout is for IE
    alert "You just killed me..."  if wnd.closed
  ), 10

$("#google-login-btn").click ->
  openWindow('/auth/google')
$("#twitter-login-btn").click ->
  openWindow('/auth/twitter')
$("#fb-login-btn").click ->
  openWindow('/auth/facebook')

AppRouter = Backbone.Router.extend
  routes:
    "":"empty"
    ":id": "statement"

  connect_socket_io: ->
    console.log "creating connection for socket io"

    @socket=socket = io.connect(url, options)

    @socket.on 'connect', ->
      console.info 'successfully established a working connection'

    @socket.on 'error', (err)->
      console.info 'Socket IO Error:', err

    @socket.on "statement", (stmts)=>
      console.log "receiving data over socket"
      @models.cache.add stmts, merge: true

  empty: ->
    console.log "empty handler called"

  statement: (id) ->
    console.log "updating page to:", id
    @models.page.set "id", parseInt id

  initialize: ->
    console.log "initializing router"
    @connect_socket_io()

    @models=
      page : page = new models.Page()
      cache : cache =  new models.Cache()
      right_side : right_side = new models.Side()
      left_side : left_side = new models.Side()

    console.log "models:",@models
    @views=
      titleView : new views.TitleView
        el: "#title"

      left_side : new views.SideView
        collection : @models.left_side
        el : "#left-side"

      right_side : new views.SideView
        collection : @models.right_side
        el : "#right-side"
    
    cache.on "add", (model, collection, options) =>
      #scan through points and put into appropriate sides
      console.log "receiving data in cache:", model
      model.socket= @socket
      id= @models.page.get "id"
      model_id=model.get("id")
      console.log "current title id:", id, "model incoming:", model_id, typeof(model_id)
      if model_id==id
        console.log "cache add title model"
        @views.titleView.update_model(model)
      else if model.get("parent")==id
        switch model.get "side"
          when "pro"
            console.log "cache add left side"
            left_side.add(model)
          when "contra"
            console.log "cache add right side"
            right_side.add(model)

    page.on "change", =>
      console.log "page change called"
      if page.hasChanged "id"
        id= page.get "id"
        console.log "page change:", id
        @socket.emit "get", id
        left_points= cache.where parent: id, side: "pro"
        right_points= cache.where parent: id, side: "contra"
        left_side.reset left_points
        right_side.reset right_points
        @views.titleView.update_model cache.get id

router= new AppRouter()
Backbone.history.start();


