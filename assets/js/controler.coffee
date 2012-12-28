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

  empty: ->

  connect_socket_io: ->
    console.log "creating connection for socket io"
    @socket=socket = io.connect(url, options)
    @socket.on "statement", (stmts)=>
      @collections.cache.add stmts, merge: true

  statement: (id) ->
    @models.page.set "id", id

  initialize: ->
    console.log "initializing router"
    @connect_socket_io()

    @models=
      page : page = new models.Page()
      cache : cache =  new models.Cache()
      right_side : right_side = new models.Side()
      left_side : left_side = new models.Side()

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
      if model.get("id")==@id
        @views.titleView.update_model(model)
      else if model.get("parent")==@id
        switch model.get "side"
          when "pro"
            left_side.add(model)
          when "contra"
            right_side.add(model)

    page.on "change", =>
      if page.hasChanged "id"
        id= page.get "id"
        socket.emit "get", id
        left_points= cache.where parent: id, side: "pro"
        right_points= cache.where parent: id, side: "contra"
        left_side.reset left_points
        right_side.reset right_points
        @views.titleView.update_model cache.get id

router= new AppRouter()

