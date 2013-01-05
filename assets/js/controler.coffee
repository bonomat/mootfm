# require dependency
console.log "loaded the controler"
views = require "./views.coffee"
models = require "./models.coffee"
io = require 'socket.io-client'
conf = require '../../lib/conf'

if conf.debug
  url = conf.debug_url
else
  url = conf.url
options =
  transports: ['websockets']
  'force new connection':true

user = new models.User

userpanelView = new views.UserpanelView
  el: "#userpanel"
  model: user

#### button logic
openWindow = (url) ->
  created_window = window.open(url, 'login window', 'height=200','width=200','modal=yes','alwaysRaised=yes')
  $(created_window).unload ->
    router.connect_socket_io()

openPWWindow = () ->

  # creating the 'formresult' window with custom features prior to submitting the form
  #created_window = window.open("/login",  'login window', 'height=200','width=200','modal=yes','alwaysRaised=yes')
  
  #body.write(form)
  #form.submit()
  #$(created_window.document.body).append($("#login-form"))
  alert $(created_window.document.body).children("form").html
  console.log "form submitted"
    


update_user_panel_buttons = () ->
  $("#google-login-btn").click ->
    openWindow('/auth/google')
  $("#twitter-login-btn").click ->
    openWindow('/auth/twitter')
  $("#fb-login-btn").click ->
    openWindow('/auth/facebook')
  $("#pw-login-btn").click (e)->
    username = $("#username").val()
    password = $("#password").val()
    e.preventDefault()
    $.post "/login",
      username: $("#username").val()
      password: $("#password").val()
    , (html) ->      
      router.connect_socket_io()
      htmlObject = document.createElement("div")
      htmlObject.innerHTML = html
      b = $(htmlObject).find("#errors")
      console.log $(b).text()
      # TODO show this error somewhere
      $("#errors").html(b.text())



update_user_panel_buttons()

AppRouter = Backbone.Router.extend
  routes:
    "":"empty"
    ":id": "statement"
    ":id/vote/:point/:amount": "vote"

  connect_socket_io: ->
    console.log "creating connection for socket io"
    @socket= socket = io.connect(url, options)

    @socket.on 'connect', ->
      console.info 'successfully established a working connection'

    @socket.on 'error', (err)->
      console.info 'Socket IO Error:', err

    @socket.on "statement", (stmts)=>
      for stmt in stmts
        if stmt.cid 
          model= @models.cache.get stmt.cid 
          model.set stmt
        else
          @models.cache.add stmt, merge: true

    @socket.on "loggedin", (username) ->
      user.set(loggedin: true, username:username)

  empty: ->
    console.log "empty handler called"

  statement: (id) ->
    console.log "setting page to ", id
    @models.page.set "id", parseInt id

  vote: (id,point_id, amount) ->
    point = @models.cache.get parseInt point_id
    @socket.emit "vote", point, parseInt amount 
    @navigate('/'+id, replace: true);

  initialize: ->
    @connect_socket_io()
    @models=
      page : page = new models.Page()
      
      cache : cache =  new models.Cache()
      
      left_side : new models.Side()
      right_side : new models.Side()
      left_input_bucket : new models.InputBucket()
      right_input_bucket : new models.InputBucket()

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
        collection : @models.left_input_bucket
        side: "pro"
        el: "#left-input"
      
      right_input: new views.InputView
        collection : @models.right_input_bucket
        side: "contra"
        el: "#right-input"

    for bucket in [@models.left_input_bucket, @models.right_input_bucket]
      bucket.on "add", (input_model, collection, options) =>
        input_model.set "parent", @models.page.get "id"
        @models.cache.add input_model
        input_model.set "cid", input_model.cid
        @socket.emit "post", input_model
        bucket.reset()

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
            @models.left_side.add(model)
          when "contra"
            @models.right_side.add(model)

    page.on "change", =>
      if page.hasChanged "id"
        id= page.get "id"
        @socket.emit "get", id
        left_points= cache.where parent: id, side: "pro"
        right_points= cache.where parent: id, side: "contra"
        @models.left_side.reset left_points
        @models.right_side.reset right_points
        @views.titleView.update_model cache.get id

    for side in [@models.left_side, @models.right_side]
      side.on "reset", =>
        cache.each (point)->
          cache.trigger "add", point

    cache.on "change", (model)=>
        if model.hasChanged "parent" or model.hasChanged "vote"
          cache.trigger "add", model

router= new AppRouter()
Backbone.history.start();

