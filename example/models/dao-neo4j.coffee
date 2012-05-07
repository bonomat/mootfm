DatabaseHelper = require "./db-helper"
Statement = require "./statement"
User = require "./user"
async = require "async"

module.exports = class DAONeo4j
  constructor: (server_address) ->
    @helper = new DatabaseHelper server_address

  new_statement: (title, callback) ->
    @helper.create_node {title:title, type:"statement"}, (err,node)->
      return callback err if err
      statement = new Statement node["id"]
      statement.votes={}
      statement.title=title
      statement.type="statement"
      callback null,statement
      
  delete_statement: (statement, callback) ->
    return callback new Error "encountered not valid statement" if not statement.id
    @helper.delete_node_by_id statement.id, (err)->
      callback err
      
  get_statement: (id, callback) ->
    @helper.get_node_by_id id, (err,node)->
      return callback err if err
      return new Error "got wrong node back" if node["id"]!=id
      return new Error "got wrong node back" if node.data.type!="statement"
      statement = new Statement id
      statement.title=node.data.title
      statement.type=node.data.type
      statement.votes={} #needs fix
      callback null, statement 
      
  new_argument: (title,side,statement,callback) ->
    @new_statement title, callback
      
  new_user: (name,callback)->
    data={type:"user",name:name}
    @helper.create_node data, (err,node)->
      return callback err if err
      user = new User node["id"]
      user.name=name
      callback null,user
      
  get_user_by_id: (id,callback)->
    @helper.get_node_by_id id, (err,node)->
      return callback err if err
      return new Error "got wrong node back" if node["id"]!=id
      user = new User id
      user.name=node.data.name
      callback null, user