models = require "./models.coffee"

module.exports.TitleView = Backbone.View.extend
  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#title_template").html())

    # Load the compiled HTML into the Backbone "el"
    if @model
      $(@el).html template @model.toJSON()
    return @

  update_model: (@model)->
    @render()

module.exports.InputView = Backbone.View.extend
  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#input_template").html())

    # Load the compiled HTML into the Backbone "el"
    if @model
      $(@el).html template @model.toJSON()
    return @

  reset_model: (model)->
    if model
      @model=model
      model.set "title", @$el.find("textarea").val()
    else
      @model = new models.Point(title: @$el.find("textarea").val())

    @render()


module.exports.PointView = PointView = Backbone.View.extend
  initialize: ->
    @render()
    @model.on "change", =>
      if (@model.hasChanged("votes"))
        @render()

  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#point_template").html())

    # Load the compiled HTML into the Backbone "el"
    $(@el).html template @model.toJSON()
    @

module.exports.SideView = Backbone.View.extend
  initialize : (options) ->
    _(this).bindAll "add", "remove"
    @_pointViews = {}
    @collection.each @add
    @collection.bind "add", @add
    @collection.bind "remove", @remove
    @collection.on "reset", =>
      @render()
    @render()

  render: ->
    # We keep track of the rendered state of the view
    @_rendered = true
    $(@el).empty()
    sorted_ids = @collection.pluck "id"
    _(sorted_ids).each (id) =>
      pointView=@_pointViews[id]
      $(@el).append pointView.render().el
    return @

  add: (point) ->
    pointview = new PointView(
      tagName: "li"
      model: point
    )

    # And add it to the collection so that it's easy to reuse.
    @_pointViews[point.get("id")] = pointview

    index=@collection.indexOf(point)

    # If the view has been rendered, then
    # we immediately append the rendered donut.
    if @_rendered
      rendered_item=pointview.render().$el
      if (index==@collection.length-1)
        @$el.append rendered_item
      else
        rendered_item.insertBefore @$el.children("li").eq(index)[0]
    return @

  remove: (model) ->
    viewToRemove = _(@_pointViews).select((collection_view) ->
      collection_view.model is model
    )[0]
    @_pointViews = _(@_pointViews).without(viewToRemove)
    $(viewToRemove.el).remove() if @_rendered

module.exports.UserpanelView = UserpanelView = Backbone.View.extend
  initialize: ->
    @render()
    @model.on "change", =>
      if (@model.hasChanged("loggedin"))
        @render()

  render: ->
    console.log "user updated", @model.get('loggedin'), @model.get('username')
    if !(@model.get('loggedin'))
      template = Handlebars.compile($("#not_loggedin_template").html())
    else
      template = Handlebars.compile($("#loggedin_template").html())

    # Load the compiled HTML into the Backbone "el"
    $(@el).html template @model.toJSON()
    @
