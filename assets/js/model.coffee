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

module.exports.Side = Backbone.Collection.extend(model: Point)