should=require 'should'
async = require "async"
User = require "../models/user"

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

  it "tests find an existing google user by using the wrapper method", (done)->
    google_user=
      name: "Tobias Hönisch"
      email: "tobias@hoenisch.at"
      id: "unknownGoogleID"
    User.find_or_create_google_user google_user, (err, create_user)->
      return done(err) if err
      create_user.exists.should.be.true
      User.get_by_google_id google_user.id,(err, db_users) ->
        return done(err) if err
        db_users.email.should.eql "tobias@hoenisch.at"
        db_users.google_id.should.eql "unknownGoogleID"
        done()


  it "tests find an existing twitter user by using the wrapper method", (done)->
    twitter_user=
      name: "Tobias Hönisch"
      screen_name: "twitterUsername"
      id: "unknownTwitterID"
    User.find_or_create_twitter_user twitter_user, (err, create_user)->
      return done(err) if err
      create_user.exists.should.be.true
      User.get_by_twitter_id twitter_user.id,(err, db_users) ->
        return done(err) if err
        db_users.username.should.eql "twitterUsername"
        db_users.twitter_id.should.eql "unknownTwitterID"
        done()

