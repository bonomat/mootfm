# require dependency
view = require "./view.coffee"
models = require "./models.coffee"

titleView = new view.TitleView
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
  id: 2
  title: "Apple is walled garden"
  parent: 1
  votes: 13
  side: "pro"
  user:
    userid:2
    name: "Franz"
    picture_url: "./placeholder.gif"
    
contra1 = new models.Point
  id: 2
  title: "Apple has best selling iphone"
  parent: 1
  votes: 13
  side: "contra"
  user:
    userid:3
    name: "Siri"
    picture_url: "./placeholder.gif"
      

#pro = new models.Side [pro1 pro2]
#contra = new models.Side [contra1]

console.log "Controler Loaded"
