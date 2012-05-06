should=require 'should'
async = require "async"
Statement = require("../models/statement")

DatabaseHelper = require("../models/db-helper")
DAONeo4j = require("../models/dao-neo4j")

describe "Statement:", ->
  helper = new DatabaseHelper "http://localhost:7474"
  db = new DAONeo4j "http://localhost:7474"

  beforeEach (done) ->
    helper.delete_all_nodes done
    
  it "create statement", (done)->
    db.create_statement "Apple is crap", (err,statement)->
      return done(err) if err
      helper.get_all_node_ids (err,ids)->
        return done(err) if err
        ids.should.have.lengthOf 1, "we should see 1 node in the db"
        statement.id.should.eql ids[0], "statement should have the id of the node in the db"
        done()
        
  it "delete statement", (done)->
    db.create_statement "Apple is crap", (err,statement)->
      helper.get_all_node_ids (err,ids)->
        db.delete_statement statement, (err)->
          return done(err) if err
          helper.get_all_node_ids (err,ids)->
            return done(err) if err
            ids.should.have.lengthOf 0, "db should be empty by now"
            done()
            
  it "wrong delete statement", (done)->
    statement = {}
    db.delete_statement statement, (err)->
      err.should.be.an.instanceof(Error)
      done()

  it "delete statement with wrong id", (done)->
    statement = new Statement 1337
    db.delete_statement statement, (err)->
      err.should.be.an.instanceof(Error)
      done()
      
  it "get statement", (done)->
    db.create_statement "Apple is crap", (err,created_statement)->
      db.get_statement created_statement.id, (err,get_statement)->
        return done(err) if err
        get_statement.should.eql created_statement, "we should get back the same statement"
        done()
