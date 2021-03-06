should=require 'should'
async = require "async"
Statement = require "../models/statement"
User = require '../models/user'

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
      statement.type.should.eql "point"
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
        get_statement.type.should.eql "point"
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
          get_statement.type.should.eql "point"
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

  it "get or create arguepoint", (done)->
    statement_data=
      title: "Apple is crap"
    pro_statement_data=
      title: "Apple has child labour in China"
    async.map [statement_data, pro_statement_data ], (item,callback)->
      Statement.create item, callback
    , (err, [statement, pro_statement ]) ->
      return done(err) if err
      statement.get_or_create_argue_point pro_statement._node,"pro", (err, arguepoint)->
        return done(err) if err
        should.exist arguepoint, "no arguepoint created"
        arguepoint.data.should.have.property 'type','arguepoint', "arguepoint type is wrong"
        arguepoint.should.have.property 'id'
        pro_statement._node.createRelationshipTo arguepoint, "", {}, (err)->
          return done(err) if err
          statement.get_or_create_argue_point pro_statement._node,"pro", (err, votepoint2)->
            return done(err) if err
            votepoint2.id.should.eql arguepoint.id, "arguepoint ids do not match"
            votepoint2.data.should.have.property 'type','arguepoint', "votepoint2 type is wrong"
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
      pro_statement.argue statement, "pro", (err)->
        return done(err) if err
        statement.getArguments (err, all_arguments)->
          return done(err) if err
          all_arguments.should.have.property('pro').with.lengthOf 1, "wrong pro arguments found"
          all_arguments["pro"][0].title.should.equal "Apple has child labour in China"
          done()

  it "unargue", (done)->
    #TODO implement this test
    return done()
    statement_data=
      title: "Apple is crap"
    pro_statement_data=
      title: "Apple has child labour in China"
    async.map [statement_data, pro_statement_data ], (item,callback)->
      Statement.create item, callback
    , (err, [statement, pro_statement ]) ->
      return done(err) if err
      pro_statement.argue statement, "pro", (err)->
        return done(err) if err
        pro_statement.unargue statement, "pro", (err)->
          return done(err) if err
          statement.getArguments (err, all_arguments)->
            return done(err) if err
            all_arguments.should.eql {}
            done()



  it "convert to representation lv 1", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err, user)->
      statement_data=
        title: "Apple is crap"
      pro_statement_data=
        title: "Apple has child labour in China"
      contra_statement_data=
        title: "Apple has best selling smart phone"
      async.map [statement_data, pro_statement_data,contra_statement_data ], (item,callback)->
        Statement.create item, callback
      , (err, [statement, pro_statement, contra_statement ]) ->
        return done(err) if err
        async.map [[pro_statement,"pro"],[contra_statement,"contra"] ], ([argument, side],callback)->
          argument.argue statement, side, callback
        , (err) ->
          return done(err) if err
          statement.get_representation 1, (err, representation)=>
            return done(err) if err
            representation.should.have.property('title',"Apple is crap")
            representation.should.have.property('id')
            representation.should.have.property('sides')
            sides=representation["sides"]
            sides.should.have.property('pro').with.lengthOf(1);
            sides.should.have.property('contra').with.lengthOf(1);
            sides["pro"][0].should.have.property('title', "Apple has child labour in China")
            sides["pro"][0].should.have.property('id')
            sides["pro"][0].should.not.have.property('sides')
            sides["pro"][0].should.have.property('vote',0)
            sides["contra"][0].should.have.property('title', "Apple has best selling smart phone")
            sides["contra"][0].should.have.property('id')
            sides["contra"][0].should.not.have.property('sides')
            sides["pro"][0].should.have.property('vote',0)
            user.vote statement, pro_statement, "pro", 1, (err,total_votes)=>
              return done(err) if err
              statement.get_representation 1, (err, representation)=>
                return done(err) if err
                representation.should.have.property('sides')
                sides=representation["sides"]
                sides["pro"][0].should.have.property('vote',1, "we should see the correct number of votes=1")
                done()


  it "convert to representation lv 0", (done)->
    statement_data=
      title: "Apple is crap"
    pro_statement_data=
      title: "Apple has child labour in China"
    contra_statement_data=
      title: "Apple has best selling smart phone"
    async.map [statement_data, pro_statement_data,contra_statement_data ], (item,callback)->
      Statement.create item, callback
    , (err, [statement, pro_statement, contra_statement ]) ->
      return done(err) if err
      async.map [[pro_statement,"pro"],[contra_statement,"contra"] ], ([argument, side],callback)->
        argument.argue statement, side, callback
      , (err) ->
        return done(err) if err
        statement.get_representation 0, (err, representation)->
          return done(err) if err
          representation.should.have.property('title',"Apple is crap")
          representation.should.have.property('id')
          representation.should.not.have.property('sides')
          done()

it "voting", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err, user)->
      statement_data=
        title: "Apple is crap"
      pro1_statement_data=
        title: "Apple has child labour in China"
      pro2_statement_data=
        title: "Apple has best selling smart phone"
      async.map [statement_data, pro1_statement_data,pro2_statement_data ], (item,callback)=>
        Statement.create item, callback
      , (err, [statement, pro1_statement, pro2_statement ]) =>
        return done(err) if err
        async.map [pro1_statement,pro2_statement ], (argument,callback)=>
          argument.argue statement, "pro", callback
        , (err) ->
          return done(err) if err
          Statement.get_votes statement, pro1_statement, "pro", (err, votes) ->
            return done(err) if err
            votes.should.eql 0
            user.vote statement, pro1_statement, "pro", -1, (err,total_votes)=>
              return done(err) if err
              total_votes.should.eql -1
              Statement.get_votes statement, pro1_statement, "pro", (err, votes) ->
                return done(err) if err
                votes.should.eql -1
                done()