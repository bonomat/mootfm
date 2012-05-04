neo4j = require("neo4j")

class DatabaseHelper
  constructor: (server_address) ->
    @db = new neo4j.GraphDatabase(server_address)

  get_node_by_id: (id,errback, callback) ->
    query = "START nodes = node(#{id}) RETURN nodes"
    ids=[]
    @db.query(query, (err,result) ->
      if err
        errback err
      else
        for row in result
          ids[ids.length]=row["nodes"]
        callback ids
      )
      
  delete_node_by_id: (id,errback,callback) ->
    query = "START nodes = node(#{id}) RETURN nodes"
    @db.query(query, (err,result) ->
      if err
        errback err
      else
        for row in result
          row["nodes"].del ((err) -> callback err), true
        callback()
      )
      
  get_all_node_ids: (errback, callback) ->
    @get_node_by_id "*",errback, (nodes) ->
      ids=[]
      for node in nodes
        ids[ids.length]=node["id"]
      callback ids
    
    
  delete_all_nodes: (errback,callback) ->
    @delete_node_by_id "*",errback, callback
    
module.exports = DatabaseHelper
