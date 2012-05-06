should=require 'should'
async = require "async"

DatabaseHelper = require("../models/db-helper")
DAONeo4j = require("../models/dao-neo4j")

describe "Statement", ->
  helper = new DatabaseHelper "http://localhost:7474"
  db = new DAONeo4j "http://localhost:7474"

  beforeEach (done) ->
    helper.delete_all_nodes (err,result)->
      return done(err) if err
      done()
    
  it "inital empty db", (done)->
    helper.get_all_node_ids (err, ids)->
      return done(err) if err
      ids.should.have.lengthOf(0)
      done()
      
  it "create node", (done)->
    data={}
    helper.create_node data, (err,node)->
      return done(err) if err
      helper.get_all_node_ids (err, ids)->
        return done(err) if err
        ids.should.have.lengthOf(1)
        done()
        
  it "create and delete node", (done)->
    data={}
    helper.create_node data, (err,node)->
      return done(err) if err
      helper.get_all_node_ids (err, ids)->
        return done(err) if err
        ids.should.have.lengthOf(1)
        helper.delete_node_by_id node['id'], (err)->
          return done(err) if err
          helper.get_all_node_ids (err, ids)->
            return done(err) if err
            ids.should.have.lengthOf(0)
            done()
    
  it "create and delete multiple nodes", (done)->
    data={}
    n=1 #wieso ist das so langsam für 20? #concurrency issues -> therefore 1 for now
    async.forEach [1..n], ((i,callback) ->
      helper.create_node data, (err,node)->
        return done(err) if err
        helper.get_all_node_ids (err, ids)->
          return done(err) if err
          ids.length.should.be.above(0)
          helper.delete_node_by_id node['id'], (err)->
            return done(err) if err
            callback()
            
      ), (err) ->
        helper.get_all_node_ids (err, ids)->
          return done(err) if err
          ids.should.have.lengthOf(0)
          done()
      
  it "create statement", (done)->
    db.create_statement "Apple is crap", (err,statement)->
      return done(err) if err
      helper.get_all_node_ids (err,ids)->
        return done(err) if err
        ids.should.have.lengthOf(1, "we should see 1 node in the db")
        done()      
