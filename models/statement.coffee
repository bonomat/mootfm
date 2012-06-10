# all we'll really store is the node; the rest of our properties will be
# derivable or just pass-through properties (see below).
Statement = module.exports = Statement = (@_node) ->

neo4j = require("neo4j")
db = new neo4j.GraphDatabase(process.env.NEO4J_URL or "http://localhost:7474")

INDEX_NAME = "nodes"
INDEX_KEY = "type"
INDEX_VAL = "statements"

proxyProperty = (prop, isData) ->
  Object.defineProperty Statement::, prop,
    get: ->
      if isData
        @_node.data[prop]
      else
        @_node[prop]

    set: (value) ->
      if isData
        @_node.data[prop] = value
      else
        @_node[prop] = value

# constants:
proxyProperty "id"
proxyProperty "exists"
proxyProperty "title", true

Statement::_getFollowingRel = (other, side, callback) ->
  query = "
    START statement=node(#{@id}), other=node(#{other.id})
    MATCH (statement) -[rel?:#{side}]-> (other)
    RETURN rel
  "
  db.query query,(err, results) ->
    return callback(err) if err
    rel = results[0] and results[0]["rel"]
    callback null, rel

Statement::save = (callback) ->
  @_node.save callback

Statement::del = (callback) ->
  @_node.del callback, true # true = yes, force it (delete all relationships)

Statement::argue = (other, side, callback) ->
  @_node.createRelationshipTo other._node, side, {}, callback

Statement::unargue = (other,side, callback) ->
  @_getFollowingRel other, side, (err, rel) ->
    return callback(err)  if err
    return callback(null)  unless rel
    rel["delete"] callback

Statement::getArguments = (callback) ->
  query ="
    START statement=node(#{@id}), arguments=node:#{INDEX_NAME}(#{INDEX_KEY}=\"#{INDEX_VAL}\")
    MATCH (arguments) -[side]-> (statement)
    RETURN arguments, TYPE(side)
    "
  user = this
  db.query query, (err, results) ->
    return callback(err)  if err
    sides = {}
    i = 0
    side_list = (result["TYPE(side)"] for result in results)
    for side in side_list when side
      sides[side]=[]
    for result in results
      sides[result["TYPE(side)"]].push new Statement(result["arguments"])
    callback null, sides

# static methods:

Statement.get = (id, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new Statement(node)

# creates the statement and persists (saves) it to the db, incl. indexing it:
Statement.create = (data, callback) ->
  node = db.createNode(data)
  statement = new Statement(node)
  node.save (err) ->
    return callback(err)  if err
    node.index INDEX_NAME, INDEX_KEY, INDEX_VAL, (err) ->
      return callback(err)  if err
      callback null, statement