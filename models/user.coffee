# all we'll really store is the node; the rest of our properties will be
# derivable or just pass-through properties (see below).
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
proxyProperty "twitter_id", true
proxyProperty "google_id", true
proxyProperty "facebook_id", true


User::save = (callback) ->
  @_node.save callback

User::del = (callback) ->
  @_node.del callback, true # true = yes, force it (delete all relationships)

# static methods:

User.get = (id, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new User(node)

User.get_by_email = (email, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new User(node)

User._get_by_property = (property, value, callback) ->
  query = "
    START n=node:#{INDEX_NAME}(#{INDEX_KEY}= \"#{INDEX_VAL}\")
    WHERE n.#{property} = \"#{value}\"
    RETURN n
  "
  db.query query, (err, results) ->
    return callback(err) if err
    node = results[0] and results[0]["n"]
    callback null, new User(node)

User.get_by_email = (email, callback) ->
  User._get_by_property "email", email, callback

User.get_by_twitter_id = (twitter_id, callback) ->
  User._get_by_property "twitter_id", twitter_id, callback

User.get_by_google_id = (google_id, callback) ->
  User._get_by_property "google_id", google_id, callback

User.get_by_facebook_id = (facebook_id, callback) ->
  User._get_by_property "facebook_id", facebook_id, callback

# creates the statement and persists (saves) it to the db, incl. indexing it:
User.create = (data, callback) ->
  node = db.createNode(data)
  user = new User(node)
  node.save (err) ->
    return callback(err)  if err
    node.index INDEX_NAME, INDEX_KEY, INDEX_VAL, (err) ->
      return callback(err)  if err
      callback null, user