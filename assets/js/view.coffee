module.exports.TitleView = Backbone.View.extend
  initialize: ->
    @render()

  render: ->
    # Compile the template using Handlebars
    template = Handlebars.compile($("#title_template").html())
    
    # Load the compiled HTML into the Backbone "el"
    $(@el).html template @model.toJSON()