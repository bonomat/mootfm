# require dependency
views = require "./views.coffee"
models = require "./models.coffee"

titleView = new views.TitleView
  el: "#title"
  model: new models.Title
    id: 1
    title: "Apple sucks"
    parent: 0
    user:
      userid:1
      name: "Tobias"
      picture_url: "./placeholder.gif"


pro1 = new models.Point
  id: 2
  title: "Apple has child Labour"
  parent: 1
  votes: 13
  side: "pro"
  user:
    userid:1
    name: "Tobias"
    picture_url: "./placeholder.gif"

pro2 = new models.Point
  id: 3
  title: "Apple is walled garden"
  parent: 1
  votes: 2
  side: "pro"
  user:
    userid:2
    name: "Franz"
    picture_url: "./placeholder.gif"

contra1 = new models.Point
  id: 4
  title: "Apple has best selling iphone"
  parent: 1
  votes: 9
  side: "contra"
  user:
    userid:3
    name: "Siri"
    picture_url: "./placeholder.gif"


pro_side = new models.Side [pro1]
#contra_side = new models.Side [contra1]

sideView = new views.SideView
  collection : pro_side
  el : "#left-side"

#sideView = new views.SideView
#  collection : contra_side
#  el : "#right-side"


pro_side.add pro2

#pro2.set(votes:99)


