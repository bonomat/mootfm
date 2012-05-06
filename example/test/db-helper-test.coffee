should=require 'should'
async = require "async"

DatabaseHelper = require "../models/db-helper"

describe "DB Helper:", ->
  helper = new DatabaseHelper "http://localhost:7474"

  beforeEach (done) ->
    helper.delete_all_nodes done
    
  it "inital empty db", (done)->
    helper.get_all_node_ids (err, ids)->
      return done(err) if err
      ids.should.have.lengthOf 0
      done()
      
  it "create node", (done)->
    data={}
    helper.create_node data, (err,node)->
      return done(err) if err
      helper.get_all_node_ids (err, ids)->
        return done(err) if err
        ids.should.have.lengthOf 1
        done()

  it "get node", (done)->
    data={}
    helper.create_node data, (err,create_node)->
      helper.get_node_by_id create_node["id"], (err, get_node)->
        return done(err) if err
        get_node["id"].should.eql create_node["id"], "we should get back the same node"
        done()
        
  it "create multiple nodes", (done)->
    data={}
    n=20
    created_node_ids=[]
    async.forEach [1..n], ((i,callback) ->
      helper.create_node data, (err,node)->
        return done(err) if err
        created_node_ids.push node["id"]
        callback()
      ), (err) ->
        helper.get_all_node_ids (err, ids)->
          return done(err) if err
          ids.should.have.lengthOf n
          created_node_ids.should.have.lengthOf n
          for id in ids
            created_node_ids.should.includeEql(id)
          done()   
               
  it "delete node", (done)->
    data={}
    helper.create_node data, (err,node)->
      helper.delete_node_by_id node['id'], (err)->
        return done(err) if err
        helper.get_all_node_ids (err, ids)->
          return done(err) if err
          ids.should.have.lengthOf 0
          done()
            
  it "delete not existant node", (done)->
    helper.delete_node_by_id 1, (err)->
      err.should.be.an.instanceof(Error)
      done()
    
  it "delete multiple nodes", (done)->
    data={}
    n=1 #wieso ist das so langsam für 20? #concurrency issues -> therefore 1 for now
    async.forEach [1..n], ((i,callback) ->
      helper.create_node data, (err,node)->
        helper.delete_node_by_id node['id'], (err)->
          return done(err) if err
          callback()
            
      ), (err) ->
        helper.get_all_node_ids (err, ids)->
          return done(err) if err
          ids.should.have.lengthOf 0
          done()
      
