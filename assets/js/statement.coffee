_.templateSettings.interpolate = /\{\{(.+?)\}\}/g;

Statement = Backbone.Model.extend(
  urlRoot:"/vo/statement",
  defaults:
    title: "Cool Title"
    id:0
    sides: {}

  initialize: ->
    @bind "change:title", ->
      title = @get("title")

  change_title: (title) ->
    @set title: title
)

StatementView = Backbone.View.extend(

  initialize: (statement)->
    @el=$("#statement_container")
    console.log statement
    @model=statement
    @model.bind "change", @render, @
    @model.bind "destroy", @close, @

    @render()
    return @

  render: ->
    template = _.template( $("#statement_template").html(), {title: @model.get("title")});
    @el.html template
    for point in @model.get("sides")["pro"]
      @el.find("#left-side").append _.template( $("#point_template").html(), point);
    for point in @model.get("sides")["contra"]
      @el.find("#right-side").append _.template( $("#point_template").html(), point);

  close: ->
      $(@el).unbind()
      $(@el).remove()
)
statement_view = new StatementView new Statement
  title:"cool"
  id:5
  sides:
    pro:
      [
        title: "pro1"
        id: 7
      ,
        title: "pro2"
        id: 8
      ]
    contra:
      [
        title: "contra1"
        id: 9
      ,
        title: "contra2"
        id: 10
      ]

