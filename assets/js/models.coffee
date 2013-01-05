module.exports.Page = Page= Backbone.Model.extend
  defaults:
    id:0

module.exports.Point = Point= Backbone.Model.extend
  defaults:
    title: ""
    parent: 0
    vote: 0
    side: "pro"
    #user:
    #  userid:0
    #  name: ""
    #  picture_url: "./placeholder.gif"

  sync: (method, model, options) ->
    #entry point for method
    switch day
      when "create"
        model.socket.emit "post", model.toJSON()
        model.socket.once "statement", (stmt)-> #TODO fix race condition with proper temp ids
          model.set stmt

      when "read" 
        model.socket.emit "get", model.id
        # response will be handled in the controler and model will be updated in the cache

      when "update" 
        console.log "ERROR: backbone sync update is not implemented!"

      when "delete" 
        console.log "ERROR: backbone sync deleteis not supported!"

      else 
        console.log "Backbone Error encountered! wrong sync method: ", method


module.exports.Side = Backbone.Collection.extend
  model: Point
  comparator: (point)->
    return point.get("votes")*-1
  initialize: ->
    @bind "change", ->
      @sort()

module.exports.User = User = Backbone.Model.extend
  defaults:
    loggedin: false
    username: ""

module.exports.InputBucket = InputBucket = Backbone.Collection.extend
  model: Point

module.exports.Cache = Backbone.Collection.extend
  model: Point
