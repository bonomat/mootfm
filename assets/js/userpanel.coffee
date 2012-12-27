module.exports.UserpanelView = Backbone.UserpanelView.extend
  initialize: ->
    @render()

  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#userpanel_template").html())

    # Load the compiled HTML into the Backbone "el"
    $(@el).html template @model.toJSON()

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