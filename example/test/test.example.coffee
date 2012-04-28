zombie = require("zombie")
require("expectThat.mocha")

browser = new zombie.Browser()

describe "When visiting our site", ->
  expectThat "the user should see the number 1", (done) ->
    browser.visit "http://localhost:8080", ->
      console.log browser.outerhtml
      p = browser.body.querySelector "#test"
      p.value.should equal "Eat this"
      done()
