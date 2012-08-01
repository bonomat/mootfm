_.templateSettings.interpolate = /\{\{(.+?)\}\}/g;

Statement = Backbone.Model.extend(
  urlRoot:"../v0/statement",
)

StatementView = Backbone.View.extend(

  initialize: ()->
    @el=$("#statement_container")
    console.log "init",@model.toJSON()
    @model.bind "change", @render, @
    @model.bind "destroy", @close, @
    @model.bind "reset", @render, @

    @render()
    return @

  render: ->
    # fix this extra error handler, why is this called with a model without stuff on it?
    return unless @model.get("title") and @model.get("sides")
    console.log "render called:", @model.toJSON()
    template = _.template( $("#statement_template").html(), {title: @model.get("title")});
    @el.html template
    for point in @model.get("sides")["pro"]
      @el.find("#left-side").append _.template( $("#point_template").html(), point);
      console.log "pro point", point
    for point in @model.get("sides")["contra"]
      @el.find("#right-side").append _.template( $("#point_template").html(), point);
      console.log "contra point", point

  close: ->
      $(@el).unbind()
      $(@el).remove()
)

AppRouter = Backbone.Router.extend(
  routes:
    "":"empty"
    ":id": "statement"
  empty: () ->
    console.log "empty route called"
    @statement = new Statement(id: 456);
    @statement.fetch()
    console.log "statement", @statement.toJSON()
    @statementView = new StatementView(model: @statement)

  statement: (id) ->
    console.log "statement route called", id
    @statement = new Statement(id: id);
    console.log "statement", @statement
    @statement.fetch()
    @statementView = new StatementView(model: @statement)
)

app = new AppRouter()
Backbone.history.start()

