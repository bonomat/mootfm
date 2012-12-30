# require dependency
console.log "loaded the controler"
views = require "./views.coffee"
models = require "./models.coffee"

io = require('socket.io-client')
url = "http://localhost:8081"
options =
  transports: ['websockets']
  'force new connection':true

testState=
  title:"Apple sucks"

user = new models.User

userpanelView = new views.UserpanelView
  el: "#userpanel"
  model: user

#### button logic
openWindow = (url) ->
  created_window = window.open(url, 'login window', 'height=200','width=200','modal=yes','alwaysRaised=yes')
  $(created_window).unload ->
    console.log "window is closed"
    router.connect_socket_io()

update_user_panel_buttons = () ->
  $("#google-login-btn").click ->
    openWindow('/auth/google')
  $("#twitter-login-btn").click ->
    openWindow('/auth/twitter')
  $("#fb-login-btn").click ->
    openWindow('/auth/facebook')

update_user_panel_buttons()

AppRouter = Backbone.Router.extend
  routes:
    "":"empty"
    ":id": "statement"

  connect_socket_io: ->
    console.log "creating connection for socket io"

    @socket= socket = io.connect(url, options)

    @socket.on 'connect', ->
      console.info 'successfully established a working connection'

    @socket.on 'error', (err)->
      console.info 'Socket IO Error:', err

    @socket.on "statement", (stmts)=>
      @models.cache.add stmts, merge: true

    @socket.on "loggedin", (username) ->
      console.log "loggin iop receiving", username
      user.set(loggedin: true, username:username)

  empty: ->
    console.log "empty handler called"

  statement: (id) ->
    @models.page.set "id", parseInt id

  initialize: ->
    @connect_socket_io()

    @models=
      page : page = new models.Page()
      
      cache : cache =  new models.Cache()
      
      left_side : left_side = new models.Side()
      right_side : right_side = new models.Side()

      left_input: left_input = new models.Point(side:"pro",parent:page.get("id"))
      right_input: right_input = new models.Point(side:"contra",parent:page.get("id"))

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

      left_input: new views.InputView
        model: @models.left_input
        el: "#left-input"
      
      right_input: new views.InputView
        model: @models.right_input
        el: "#right-input"

    for input in [right_input, left_input]
      input.on "change", =>
        if (input.hasChanged("title"))
          console.log "title changed", input.get "title"

    cache.on "add", (model, collection, options) =>
      #scan through points and put into appropriate sides
      model.socket= @socket
      id= @models.page.get "id"
      model_id= model.get "id"
      if model_id==id
        @views.titleView.update_model(model)
      else if model.get("parent")==id
        switch model.get "side"
          when "pro"
            left_side.add(model)
          when "contra"
            right_side.add(model)

    page.on "change", =>
      if page.hasChanged "id"
        id= page.get "id"
        @socket.emit "get", id
        left_points= cache.where parent: id, side: "pro"
        right_points= cache.where parent: id, side: "contra"
        left_side.reset left_points
        right_side.reset right_points
        @views.titleView.update_model cache.get id

    for side in [left_side, right_side]
      side.on "reset", =>
        cache.each (point)->
          cache.trigger "add", point

    cache.on "change", (model)=>
        if model.hasChanged "parent" or model.hasChanged "vote"
          cache.trigger "add", model

router= new AppRouter()
Backbone.history.start();

