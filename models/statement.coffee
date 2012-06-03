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
  db.query ((err, results) ->
    return callback(err) if err
    rel = results[0] and results[0]["rel"]
    callback null, rel
  ), query

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

# calls callback w/ (err, following, others) where following is an array of
# users this user follows, and others is all other users minus him/herself.
Statement::getFollowingAndOthers = (callback) ->
  query ="
    START user=node(#{@id}), other=node:#{INDEX_NAME}(#{INDEX_KEY}=\"#{INDEX_VAL}\")
    MATCH (user) -[rel?:#{FOLLOWS_REL}]-> (other)
    RETURN other, COUNT(rel)
    "
  user = this
  db.query ((err, results) ->
    return callback(err)  if err
    following = []
    others = []
    i = 0

    while i < results.length
      other = new User(results[i]["other"])
      follows = results[i]["count(rel)"]
      if user.id is other.id
        continue
      else if follows
        following.push other
      else
        others.push other
      i++
    callback null, following, others
  ), query

# static methods:

Statement.get = (id, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new Statement(node)

Statement.getAll = (callback) ->
# if (err) return callback(err);
# XXX FIXME the index might not exist in the beginning, so special-case
# this error detection. warning: this is super brittle!!
  db.getIndexedNodes INDEX_NAME, INDEX_KEY, INDEX_VAL, (err, nodes) ->
    return callback(null, [])  if err
    users = nodes.map((node) ->
      new Statement(node)
    )
    callback null, users

# creates the user and persists (saves) it to the db, incl. indexing it:
Statement.create = (data, callback) ->
  node = db.createNode(data)
  user = new Statement(node)
  node.save (err) ->
    return callback(err)  if err
    node.index INDEX_NAME, INDEX_KEY, INDEX_VAL, (err) ->
      return callback(err)  if err
      callback null, user