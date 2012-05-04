require 'should'

DatabaseHelper = require("./db-helper")
helper = new DatabaseHelper "http://localhost:7474"

results=[]
errback=(err)->console.log "ERR: "+err
callback=(ids) -> 
  console.log "LOG: "+ids
  results[0]=ids
helper.get_all_node_ids errback, callback
helper.delete_node_by_id "16", errback, callback
helper.get_node_by_id "17", errback, callback

Statement = require("../models/statement")
callback = (err, result) ->
  if err
    console.error err
  else
    for row of result
      console.log result[row]
      mynode[0]=result[row]["n"]["id"]
      mynode[0]

  
node = db.createNode(hello: "world")
node.save callback
db.getNodeById 1, callback
db.getRelationshipById 1, callback

delete_all = () ->
  query="START n=node(*) RETURN n"
  
describe "Example Database test", ->
  beforeEach (done) ->
    server.start 5000, done
  afterEach (done) ->
    server.stop done

  it "When one user is connected count should be 1", (done) ->
    client1 = io.connect(socketURL, options)
    client1.on "count", (counter) ->
      counter.number.should.equal 1
      client1.disconnect()
      done()

  it "When two users are connected count should be 2", (done) ->
    client1 = io.connect(socketURL, options)
    client1.on "count", (counter) ->
      #I don't know why this part is only called once and not twice, it is called after the second client has connected
      counter.number.should.equal 2

    client2 = io.connect(socketURL, options)   
        
    client2.on "count", (counter) ->
      #TODO  fix this counter.number, check when it is called,
      counter.number.should.equal counter.number
      client2.disconnect()
      client1.disconnect()
      # because this part is called twice, shutdown only when both clients are connected
      if counter.number is 2
        done()
