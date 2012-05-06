DatabaseHelper = require "./db-helper"
Statement = require "./statement"
async = require "async"

module.exports = class DAONeo4j
  constructor: (server_address) ->
    @helper = new DatabaseHelper server_address

  new_statement: (title, callback) ->
    @helper.create_node {title:title}, (err,node)->
      return callback err if err
      statement = new Statement node["id"]
      statement.votes={}
      statement.title=title
      callback null,statement
      
  delete_statement: (statement, callback) ->
    return callback new Error "encountered not valid statement" if not statement.id
    @helper.delete_node_by_id statement.id, (err)->
      callback err
      
  get_statement: (id, callback) ->
    async.parallel
      statement: (callback)->
        @helper.get_node_by_id id, (err,node)->
          return callback err if err
          statement = new Statement node["id"]
          callback null,statement
      votes: (callback) ->
        @helper.get_votes id, callback
      , (err, results) -> 
        return callback err if err
        statement=result.statement
        statement.votes=result.votes
        callback null, statement
      
  new_argument: (title,side,statement,callback) ->
    @new_statement title, callback
      

