should=require 'should'
async = require "async"
Statement = require "../models/statement"

DatabaseHelper = require "../models/db-helper"
DAONeo4j = require "../models/dao-neo4j"

describe "Statement:", ->
  helper = new DatabaseHelper "http://localhost:7474"
  db = new DAONeo4j "http://localhost:7474"

  beforeEach (done) ->
    helper.delete_all_nodes done
    
  it "create statement", (done)->
    db.new_statement "Apple is crap", (err,statement)->
      return done(err) if err
      helper.get_all_node_ids (err,ids)->
        return done(err) if err
        ids.should.have.lengthOf 1, "we should see 1 node in the db"
        statement.id.should.eql ids[0], "statement should have the id of the node in the db"
        done()
        
  it "delete statement", (done)->
    db.new_statement "Apple is crap", (err,statement)->
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
    db.new_statement "Apple is crap", (err,created_statement)->
      db.get_statement created_statement.id, (err,get_statement)->
        return done(err) if err
        get_statement.should.eql created_statement, "we should get back the same statement"
        done()
        
  it "get statement with wrong id", (done)->
    db.get_statement 1337, (err,get_statement)->
      err.should.be.an.instanceof(Error)
      done()
        
  it "create new argument", (done)->
    db.new_statement "Apple is crap", (err,apple_statement)->
      db.new_argument "Apple has child labour in China", "pro", apple_statement, (err,labour_statement)->
        return done(err) if err
        helper.get_all_node_ids (err,ids)->
            return done(err) if err
            ids.should.have.lengthOf 2, "we have 2 statements by now"
            done()
            
  it "create new argument for missing statement", (done)->
    missing_statement = new Statement 1337
    db.new_argument "Apple has child labour", "pro", missing_statement, (err,labour_statement)->
      err.should.be.an.instanceof(Error)
      helper.get_all_node_ids (err,ids)->
        return done(err) if err
        ids.should.have.lengthOf 1, "argument should be created even if statement is missing"
        done()
        
#  it "sides", (done)->
#    db.new_statement "Apple is crap", (err,apple_statement)->
#      db.new_argument "Apple has child labour", "pro", apple_statement, (err,labour_statement)->
#        apple_statement.sides.should.eql ["pro"], "we should have exactly one side: pro" 
#        done()
        
  it "empty votes", (done)->
    db.new_statement "Apple is crap", (err,apple_statement)->
      apple_statement.votes.should.eql {}, "we should have no sides yet" 
      done()


