Backbone = require('backbone')

module.exports.Title = Backbone.Model.extend(
  defaults:
    id: 0
    title: ""
    parent: 0
    votes: 0
    side: "pro"
    user:
      userid:0
      name: ""
      picture_url: "./placeholder.gif"
)

module.exports.Point = Point= Backbone.Model.extend(
  defaults:
    id: 0
    title: ""
    parent: 0
    votes: 0
    side: "pro"
    user:
      userid:0
      name: ""
      picture_url: "./placeholder.gif"
)

module.exports.Side = Backbone.Collection.extend
  model: Point
  comparator: (point)->
    return point.get("votes")*-1
  initialize: ->
    @bind "change", ->
      @sort()

