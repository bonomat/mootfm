#= require dependency
view = require "view"

titleView = new view.TitleView(el: $("#title"))
titleView.setTitle(new model.Title title:"Apple sucks")