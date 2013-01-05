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
  events: 
    'keydown :input': 'keypress'
  
  initialize: ->
    @collection.on "reset", =>
      @reset
    @render()

  keypress: (e)->
    if e.keyCode is 13 and not e.shiftKey
      e.preventDefault() # Makes no difference
      model = new models.Point "title": @$el.find("textarea").val(), "side":@options.side
      @collection.add model

  render: ->
    template = Handlebars.compile($("#input_template").html())
    $(@el).html template()
    return @

  reset: ->
    @$el.find("textarea").val("")

module.exports.PointView = PointView = Backbone.View.extend
  initialize: ->
    @render()

    @model.on "change", =>
      if (@model.hasChanged("vote") or @model.hasChanged("id"))
        @render()

  render: ->
    template = Handlebars.compile($("#point_template").html())
    $(@el).html template @model.toJSON()
    @

module.exports.SideView = Backbone.View.extend
  initialize : (options) ->
    @_pointViews = {}
    _(this).bindAll "add", "remove"
    @collection.each @add
    @collection.bind "add", @add
    @collection.bind "remove", @remove
    @collection.on "change:id", (model)=>
      @add_rendered_point(model)
    @collection.on "reset", =>
      @render()
    @collection.on "sort", =>
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

  add_rendered_point: (point)->
    pointview = new PointView
      tagName: "li"
      model: point
    id=point.get("id")
    @_pointViews[id] = pointview
    return pointview

  add: (point) ->
    # Add it to the collection so that it's easy to reuse.
    pointview= @add_rendered_point point

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
