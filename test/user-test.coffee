should=require 'should'
async = require "async"
User = require "../models/user"
Statement = require "../models/statement"

DatabaseHelper = require "../models/db-helper"

describe "User:", ->
  helper = new DatabaseHelper "http://localhost:7474"

  beforeEach (done) ->
    helper.delete_all_nodes done

  it "create user", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err,user)->
      return done(err) if err
      user.exists.should.be.true
      user.name.should.eql "Tobias Hönisch"
      user.email.should.eql "tobias@hoenisch.at"
      user.password.should.eql "ultrasafepassword"
      done()

  it "delete user", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err,user)->
      return done(err) if err
      user.del (err)->
        return done(err) if err
        user.exists.should.be.false
        done()

  it "get user", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err,create_user)->
      return done(err) if err
      create_user.exists.should.be.true
      User.get create_user.id, (err,get_user)->
        return done(err) if err
        get_user.should.eql create_user
        get_user.name.should.eql "Tobias Hönisch"
        done()

  it "get user functions", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
      twitter_id: "123412341234"
      google_id: "googleid1231234"
      facebook_id: "facebookskrasseid"
    user_data2=
      name: "Franzi"
      email: "franzi@moot.fm"
      password: "sexyhasi21"
      twitter_id: "franztwitter"
      google_id: "googlefranz"
      facebook_id: "facebookfranz"
    User.create user_data, (err,create_user)->
      return done(err) if err
      User.create user_data2, (err,user2)->
        return done(err) if err
        create_user.exists.should.be.true
        async.parallel [
          (callback) -> User.get_by_twitter_id user_data.twitter_id, callback
          (callback) -> User.get_by_google_id user_data.google_id, callback
          (callback) -> User.get_by_facebook_id user_data.facebook_id, callback
          (callback) -> User.get_by_email user_data.email, callback
         ], (err, db_users) ->
          return done(err) if err
          for user in db_users
            user.should.eql create_user
            user.twitter_id.should.eql "123412341234"
          done()

  it "save user", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err,create_user)->
      return done(err) if err
      create_user.name = "Tobias Hoenisch"
      create_user.save (err)->
        return done(err) if err
        User.get create_user.id, (err,get_user)->
          get_user.should.eql create_user
          get_user.name.should.eql "Tobias Hoenisch"
          done()

  it "retrieve non existant user", (done)->
    User.get 999999, (err)->
      should.exist(err)
      done()

  it "retrieve deleted user", (done)->
    user_data=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      password: "ultrasafepassword"
    User.create user_data, (err,user)->
      return done(err) if err
      user.exists.should.be.true
      id=user.id
      user.del (err)->
        return done(err) if err
        user.exists.should.be.false
        User.get id, (err)->
          should.exist(err)
          done()

  it "tests create google user by using the wrapper method", (done)->
    google_user=
      name:
        givenName: "Tobias"
        familyName: "Hönisch"
      emails:
        [value: "tobias@hoenisch.at"]
      id: "unknownGoogleID"
    User.find_or_create_google_user google_user, (err, create_user)->
      return done(err) if err
      create_user.exists.should.be.true
      User.get_by_google_id google_user.id,(err, db_users) ->
        return done(err) if err
        db_users.email.should.eql "tobias@hoenisch.at"
        db_users.google_id.should.eql "unknownGoogleID"
        done()


  it "tests create twitter user by using the wrapper method", (done)->
    twitter_user=
      name:
        givenName: "Tobias"
        familyName: "Hönisch"
      emails:
        []
      displayName: "twitterUsername"
      id: "unknownTwitterID"
    User.find_or_create_twitter_user twitter_user, (err, create_user)->
      return done(err) if err
      create_user.exists.should.be.true
      User.get_by_twitter_id twitter_user.id,(err, db_users) ->
        return done(err) if err
        db_users.username.should.eql "twitterUsername"
        db_users.twitter_id.should.eql "unknownTwitterID"
        done()

  it "tests create facebook user by using the wrapper method", (done)->
    facebook_user=
      name:
        givenName: "Tobias"
        familyName: "Hönisch"
      displayName: "facebookUser"
      id: "unknownFacebookID"
      emails:
        [value: "unknown@gmail.com"]
    User.find_or_create_facebook_user facebook_user, (err, create_user)->
      return done(err) if err
      create_user.exists.should.be.true
      User.get_by_facebook_id facebook_user.id,(err, db_users) ->
        return done(err) if err
        db_users.username.should.eql "facebookUser"
        db_users.facebook_id.should.eql "unknownFacebookID"
        done()

  it "tests validate user method with no errors", (done) ->
    newUserAttributes=
      email: 'philipp.hoenisch@gmail.com'
      name: 'Philipp Hoenisch'
      username: 'bonomat'
      password: 'test'
    User.validateUser newUserAttributes, (errors) ->
      errors.should.be.empty
      done()

  it "tests validate user method with errors ( no email defined ) ", (done) ->
    newUserAttributes=
      name: 'Philipp Hoenisch'
      username: 'bonomat'
      password: 'test'
    User.validateUser newUserAttributes, (errors) ->
      errors.should.include('No Email defined')
      done()

  it "tests validate user method with errors ( no username defined ) ", (done) ->
    newUserAttributes=
      name: 'Philipp Hoenisch'
      email: 'bonomat@gmail.com'
      password: 'test'
    User.validateUser newUserAttributes, (errors) ->
      errors.should.include('No Username defined')
      done()

  it "tests validate user method with errors ( no password defined ) ", (done) ->
    newUserAttributes=
      name: 'Philipp Hoenisch'
      email: 'bonomat@gmail.com'
      username: 'bonomat'
    User.validateUser newUserAttributes, (errors) ->
      errors.should.include('No Password defined')
      done()



describe "Voting:", ->
  helper = new DatabaseHelper "http://localhost:7474"

  beforeEach (done) =>
    helper.delete_all_nodes (err)=>
      return done(err) if err
      user_data1=
        name: "Tobias Hönisch"
        email: "tobias@hoenisch.at"
        password: "ultrasafepassword"
      user_data2=
        name: "Philipp Hönisch"
        email: "philipp@hoenisch.at"
        password: "even better password"
      async.map [user_data1, user_data2 ], (user_data,callback)->
        User.create user_data, callback
      , (err, [@user1, @user2 ]) ->
          return done(err) if err
          done()

  it "vote up", (done)->
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
        vote=1
        @user1.vote statement, pro_statement, "pro", vote, (err,total_votes)->
          return done(err) if err
          total_votes.should.eql 1
          done()

  it "vote up 2 user", (done)->
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
        vote=1
        @user1.vote statement, pro_statement, "pro", vote, (err,total_votes)->
          return done(err) if err
          total_votes.should.eql 1
          @user2.vote statement, pro_statement, "pro", vote, (err,total_votes)->
            return done(err) if err
            total_votes.should.eql 2
            done()

  it "multiple vote 2 user", (done)->
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
        vote=1
        @user1.vote statement, pro_statement, "pro", -1, (err,total_votes)->
          return done(err) if err
          total_votes.should.eql -1
          @user2.vote statement, pro_statement, "pro", 1, (err,total_votes)->
            return done(err) if err
            total_votes.should.eql 0
            done()


