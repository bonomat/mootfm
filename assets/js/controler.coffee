# require dependency
view = require "./view.coffee"
models = require "./models.coffee"

console.log "Controler Loaded"
titleView = new view.TitleView
  el: $("#title")
  model: new models.Title(title:"Apple sucks")
  

