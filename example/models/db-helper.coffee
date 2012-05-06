neo4j = require "neo4j"
async = require "async"

module.exports = class DatabaseHelper
  constructor: (server_address) ->
    @db = new neo4j.GraphDatabase(process.env.NEO4J_URL or server_address)

  get_node_by_id: (id,callback) ->
    query = "START nodes = node(#{id}) RETURN nodes"
    ids=[]
    @db.query query, (err,results) ->
      return callback err if err
      for result in results
        ids[ids.length]=result["nodes"]
      callback null, ids
      
  delete_node_by_id: (id,callback) ->
    query = "START nodes = node(#{id}) RETURN nodes"
    @db.query query, (err,results) ->
      return callback err if err
      async.forEach results, ((result, callback) ->
        result["nodes"].del callback, true
      ), (err) ->
        callback err
        
        
  create_node: (data, callback)->
    node = @db.createNode data
    node.save (err) ->
      return callback err if err 
      callback null,node

  get_all_node_ids: (callback) ->
    @get_node_by_id "*",(err, nodes) ->
      return callback err if err
      ids=[]
      for node in nodes
        ids[ids.length]=node["id"]
      callback null, ids
    
  delete_all_nodes: (callback) ->
    @delete_node_by_id "*",callback
