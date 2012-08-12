#_.templateSettings.interpolate = /\{\{(.+?)\}\}/g;
_.templateSettings.escape = /\{\{(.+?)\}\}/g;


Backbone.View::close = ->
  @remove()
  @unbind()
  @onClose() if @onClose

Statement = Backbone.Model.extend(
  urlRoot:"../v0/statement",
)

StatementView = Backbone.View.extend(
  events:
    "keydown #new_pro_point_template": "pro_keydown"
    "keydown #new_contra_point_template": "contra_keydown"

  initialize: ->
    $(@el).html _.template( $("#statement_template").html(), {})
    @model.bind "change", @render, @
    @model.bind "destroy", @close, @
    @model.bind "reset", @render, @
    return @

  onClose: ->
    @model.unbind "change", @render
    @model.unbind "destroy", @render
    @model.unbind "reset", @render

  render: ->
    # fix this extra error handler, why is this called with a model without stuff on it?
    return unless @model.get("title") and @model.get("sides")

    $("#title").html _.template( $("#title_template").html(), {title: @model.get("title")});
    $("#left-side #points").html ("")
    $("#right-side #points").html ("")
    for point in @model.get("sides")["pro"]
      $("#left-side #points").append _.template( $("#point_template").html(), point);
    for point in @model.get("sides")["contra"]
      $("#right-side #points").append _.template( $("#point_template").html(), point);

  proClick :->
    point= $("#left-side textarea").val()
    return unless point
    $("#left-side textarea").val("")
    $.post "v0/statement/#{@model.get('id')}/side/pro", {point}, (data) =>
      pro_points=@model.get("sides")["pro"]
      pro_points.push({title:point, id:data["id"]})
      @model.trigger('change')

  pro_keydown: (e)->
    if e.keyCode is 13 and not e.shiftKey
      e.preventDefault() # Makes no difference
      @proClick()

  contra_keydown: (e)->
    if e.keyCode is 13 and not e.shiftKey
      e.preventDefault() # Makes no difference
      @contraClick()

  contraClick : ->
    point= $("#right-side textarea").val()
    return unless point
    $("#right-side textarea").val("")
    $.post "v0/statement/#{@model.get('id')}/side/contra", {point}, (data) =>
      contra_points=@model.get("sides")["contra"]
      contra_points.push({title:point, id:data["id"]})
      @model.trigger('change')

  close: ->
      $(@el).unbind()
      $(@el).html _.template( $("#statement_template").html(), {})
)

class AppView
  showView: (view) ->
    @currentView.close()  if @currentView
    @currentView = view
    @currentView.render()
    $("#statement_container").html @currentView.el

AppRouter = Backbone.Router.extend(
  routes:
    "":"empty"
    ":id": "statement"
  empty: () ->
    statement = new Statement(id: 1);
    statement.fetch()
    statementView = new StatementView(model: statement)
    @appView.showView statementView

  statement: (id) ->
    statement = new Statement(id: id);
    statement.fetch()
    statementView = new StatementView(model: statement)
    @appView.showView statementView

  initialize: ->
    @appView = new AppView()
)

app = new AppRouter()
Backbone.history.start()
