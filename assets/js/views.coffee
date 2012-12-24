module.exports.TitleView = Backbone.View.extend
  initialize: ->
    @render()

  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#title_template").html())
    
    # Load the compiled HTML into the Backbone "el"
    $(@el).html template @model.toJSON()

module.exports.PointView = PointView = Backbone.View.extend
  initialize: ->
    @render()

  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#point_template").html())
    
    # Load the compiled HTML into the Backbone "el"
    $(@el).html template @model.toJSON()
    @
    
module.exports.SideView = Backbone.View.extend(
  initialize : (options) ->
    _(this).bindAll "add", "remove"
    @_pointViews = []
    console.log "collection", @collection
    @collection.each @add
    @collection.bind "add", @add
    @collection.bind "remove", @remove
    @render()

  render: ->
    # We keep track of the rendered state of the view
    @_rendered = true
    $(@el).empty()
    # Render each Donut View and append them.
    console.log "list",@_pointViews
    _(@_pointViews).each (point_view) =>
      $(@el).append point_view.render().el
      console.log "rendered 1 point"
    return @
    
  add: (point) ->
    # We create an updating donut view for each donut that is added.
    pointview = new PointView(
      tagName: "li"
      model: point
    )
    
    # And add it to the collection so that it's easy to reuse.
    @_pointViews.push pointview
    
    # If the view has been rendered, then
    # we immediately append the rendered donut.
    $(@el).append pointview.render().el if @_rendered
    return @

  remove: (model) ->
    viewToRemove = _(@_pointViews).select((collection_view) ->
      collection_view.model is model
    )[0]
    @_pointViews = _(@_pointViews).without(viewToRemove)
    $(viewToRemove.el).remove() if @_rendered
)

