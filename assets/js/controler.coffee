# require dependency
view = require "./view.coffee"
model = require "./model.coffee"

titleView = new view.TitleView(el: $("#title"))
titleView.setTitle(new model.Title title:"Apple sucks")
