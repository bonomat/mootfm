DatabaseHelper = require("./db-helper")
Statement = require("./statement")

module.exports = class DAONeo4j
  constructor: (server_address) ->
    @helper = new DatabaseHelper server_address

  create_statement: (title, callback) ->
    @helper.create_node {title:title}, (err,node)->
      if err      
        callback err
      statement = new Statement node["id"]
      callback null,statement
