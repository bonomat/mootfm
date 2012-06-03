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
        get_user.should.eql create_user
        get_user.name.should.eql "Tobias Hönisch"
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


