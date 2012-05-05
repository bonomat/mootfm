neo4j = require "neo4j"

class DatabaseHelper
  constructor: (server_address) ->
    @db = new neo4j.GraphDatabase(process.env.NEO4J_URL or server_address)

  get_node_by_id: (id,callback) ->
    query = "START nodes = node(#{id}) RETURN nodes"
    ids=[]
    @db.query query, (err,result) ->
      if err
        callback err
      else
        for row in result
          ids[ids.length]=row["nodes"]
        callback null, ids
      
  delete_node_by_id: (id,callback) ->
    query = "START nodes = node(#{id}) RETURN nodes"
    @db.query query, (err,result) ->
      if err
        callback err
      else
        for row in result
          row["nodes"].del ((err) -> callback err), true
        callback null
      
  get_all_node_ids: (callback) ->
    @get_node_by_id "*",(err, nodes) ->
      if err
        callback err
      ids=[]
      for node in nodes
        ids[ids.length]=node["id"]
      callback null, ids
    
  delete_all_nodes: (callback) ->
    @delete_node_by_id "*",callback
    
module.exports = DatabaseHelper
