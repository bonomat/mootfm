should=require 'should'

describe "DB Helper", ->
  DatabaseHelper = require("../models/db-helper")
  helper = new DatabaseHelper "http://localhost:7474"
  
  beforeEach (done) ->
    helper.delete_all_nodes (->should.fail('no error expected!')),->done()
    
  it "Every Test Case should have access to an empty DB", (done)->
    helper.get_all_node_ids (->should.fail('no error expected!')), (ids)->
      ids.should.have.lengthOf(0)
      done()
      
  
