DatabaseHelper = require("./db-helper")
Statement = require("./statement")

module.exports = class DAONeo4j
  constructor: (server_address) ->
    @helper = new DatabaseHelper server_address

  create_statement: (title, callback) ->
    @helper.create_node {title:title}, (err,node)->
      return callback err if err
      statement = new Statement node["id"]
      callback null,statement
      
      
  delete_statement: (statement, callback) ->
    return callback new Error "encountered not valid statement" if not statement.id
    @helper.delete_node_by_id statement.id, (err)->
      callback err
