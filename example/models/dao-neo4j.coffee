DatabaseHelper = require("./db-helper")
Statement = require("./statement")

class DAONeo4j
  constructor: (server_address) ->
    helper = new DatabaseHelper server_address

  create_statement: (title, callback) ->
    helper.create_node null, (err,id)->
      if err
        callback err 
      callback null,title
      
     
module.exports = DAONeo4j
