should=require 'should'
async = require "async"
Statement = require "../models/statement"
User = require "../models/user"

DatabaseHelper = require "../models/db-helper"

describe "Statement:", ->
  helper = new DatabaseHelper "http://localhost:7474"

  beforeEach (done) ->
    helper.delete_all_nodes done

  it "create statement", (done)->
    statement_data=
      title: "Apple is crap"
    Statement.create statement_data, (err,statement)->
      return done(err) if err
      statement.exists.should.be.true
      statement.title.should.eql "Apple is crap"
      done()

  it "delete statement", (done)->
    statement_data=
      title: "Apple is crap"
    Statement.create statement_data, (err,statement)->
      return done(err) if err
      statement.del (err)->
        return done(err) if err
        statement.exists.should.be.false
        done()

  it "get statement", (done)->
    statement_data=
      title: "Apple is crap"
    Statement.create statement_data, (err,create_statement)->
      return done(err) if err
      create_statement.exists.should.be.true
      Statement.get create_statement.id, (err,get_statement)->
        get_statement.should.eql create_statement
        get_statement.title.should.eql "Apple is crap"
        done()

  it "save statement", (done)->
    statement_data=
      title: "Apple is crap"
    Statement.create statement_data, (err,create_statement)->
      return done(err) if err
      create_statement.title = "Facebook IPO was awesome"
      create_statement.save (err)->
        return done(err) if err
        Statement.get create_statement.id, (err,get_statement)->
          get_statement.should.eql create_statement
          get_statement.title.should.eql "Facebook IPO was awesome"
          done()

  it "retrieve non existant statement", (done)->
    Statement.get 999999, (err)->
      should.exist(err)
      done()

  it "retrieve deleted statement", (done)->
    statement_data=
      title: "Apple is crap"
    Statement.create statement_data, (err,statement)->
      return done(err) if err
      statement.exists.should.be.true
      id=statement.id
      statement.del (err)->
        return done(err) if err
        statement.exists.should.be.false
        Statement.get id, (err)->
          should.exist(err)
          done()

  it "argue", (done)->
    statement_data=
      title: "Apple is crap"
    pro_statement_data=
      title: "Apple has child labour in China"
    async.map [statement_data, pro_statement_data ], (item,callback)->
      Statement.create item, callback
    , (err, [statement, pro_statement ]) ->
      return done(err) if err
      pro_statement.argue statement, "pro", done

#  it "create new argument", (done)->
#    db.new_statement "Apple is crap", (err,apple_statement)->
#      db.new_argument "Apple has child labour in China", "pro", apple_statement, (err,labour_statement)->
#        return done(err) if err
#        apple_statement.votes["pro"].should.eql 1, "we should see one vote by now"
#        helper.get_all_node_ids (err,ids)->
#            return done(err) if err
#            ids.should.have.lengthOf 2, "we have 2 statements by now"
#            done()

#  it "create new argument for missing statement", (done)->
#    missing_statement = new Statement 1337
#    db.new_argument "Apple has child labour", "pro", missing_statement, (err,labour_statement)->
#      err.should.be.an.instanceof(Error)
#      helper.get_all_node_ids (err,ids)->
#        return done(err) if err
#        ids.should.have.lengthOf 1, "argument should be created even if statement is missing"
#        done()

#  it "sides", (done)->
#    db.new_statement "Apple is crap", (err,apple_statement)->
#      db.new_argument "Apple has child labour", "pro", apple_statement, (err,labour_statement)->
#        apple_statement.sides.should.eql ["pro"], "we should have exactly one side: pro"
#        done()

  #it "empty votes", (done)->
    #db.new_statement "Apple is crap", (err,apple_statement)->
      #apple_statement.votes.should.eql {}, "we should have no sides yet"
      #done()

