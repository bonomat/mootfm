_.templateSettings.interpolate = /\{\{(.+?)\}\}/g;

Statement = Backbone.Model.extend(
  urlRoot:"../v0/statement",
)

StatementView = Backbone.View.extend(

  initialize: (statement)->
    @el=$("#statement_container")
    console.log statement
    @model=statement
    @model.bind "change", @render, @
    @model.bind "destroy", @close, @
    @model.bind "reset", @render, @

    @render()
    return @

  render: ->
    console.log "render called"
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

AppRouter = Backbone.Router.extend(
  routes:
    "":"empty"
    "/statement/:id": "statement"
  empty: () ->
    console.log "empty called"
    @statement = new Statement(id: 418);
    console.log "statement", @statement
    @statementView = new StatementView(model: @statement)

  statement: (id) ->
    console.log "statement called"
    @statement = new Statement(id: id);
    console.log "statement", @statement
    @statementView = new StatementView(model: @statement)
)

app = new AppRouter()
Backbone.history.start()

