User = module.exports = User = (@_node) ->

neo4j = require("neo4j")
db = new neo4j.GraphDatabase(process.env.NEO4J_URL or "http://localhost:7474")

INDEX_NAME = "nodes"
INDEX_KEY = "type"
INDEX_VAL = "user"

proxyProperty = (prop, isData) ->
  Object.defineProperty User::, prop,
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
proxyProperty "name", true
proxyProperty "email", true
proxyProperty "password", true

User::save = (callback) ->
  @_node.save callback

User::del = (callback) ->
  @_node.del callback, true # true = yes, force it (delete all relationships)

# static methods:

User.get = (id, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new User(node)

# creates the statement and persists (saves) it to the db, incl. indexing it:
User.create = (data, callback) ->
  node = db.createNode(data)
  user = new User(node)
  node.save (err) ->
    return callback(err)  if err
    node.index INDEX_NAME, INDEX_KEY, INDEX_VAL, (err) ->
      return callback(err)  if err
      callback null, user