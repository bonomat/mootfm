# all we'll really store is the node; the rest of our properties will be
# derivable or just pass-through properties (see below).
User = module.exports = User = (@_node) ->

neo4j = require("neo4j")
db = new neo4j.GraphDatabase(process.env.NEO4J_URL or "http://localhost:7474")

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
proxyProperty "type", true
proxyProperty "username", true
proxyProperty "email", true
proxyProperty "password", true
proxyProperty "twitter_id", true
proxyProperty "google_id", true
proxyProperty "facebook_id", true


User::save = (callback) ->
  @_node.save callback

User::del = (callback) ->
  @_node.del callback, true # true = yes, force it (delete all relationships)

User::_get_vote_connection_or_create = (point, callback) ->
  query = "
    START startpoint=node(#{@id}), endpoint=node(#{point.id})
    MATCH startpoint -[rel]-> endpoint
    RETURN rel
    "
  db.query query,(err, results) =>
    return callback(err) if err
    if results.length>1
      return callback "DB inconsistent: Too many matching connections found in db"
    if results.length==1
      return callback null, results[0]["rel"]
    else
      @_node.createRelationshipTo point, "", {}, callback

User::vote = (stmt, point, side, vote, callback) ->
  stmt.get_or_create_argue_point point._node,side,(err,arguepoint)=>
    @_get_vote_connection_or_create  arguepoint, (err, rel)=>
      return callback(err) if err
      rel._data.data.vote=vote
      rel.save (err)=>
        query = "
          START stmt=node(#{arguepoint.id}), users=node:nodes(type=\"user\")
          MATCH users -[rel]-> stmt
          WHERE users.type = \"user\" and users.type = \"user\" and has(rel.vote)
          RETURN sum(rel.vote)
          "
        db.query query,(err, results) =>
          return callback(err) if err
          if results.length==1
            return callback null, results[0]["sum(rel.vote)"]
          else
            return callback null, 0

# static methods:

User.get = (id, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new User(node)


User.get_by_email = (email, callback) ->
  User._get_by_property "email", email, callback

User.get_by_username = (username, callback) ->
  User._get_by_property "username", username, callback

User.get_by_twitter_id = (twitter_id, callback) ->
  User._get_by_property "twitter_id", twitter_id, callback

User.get_by_google_id = (google_id, callback) ->
  User._get_by_property "google_id", google_id, callback

User.get_by_facebook_id = (facebook_id, callback) ->
  User._get_by_property "facebook_id", facebook_id, callback

# creates the user and persists (saves) it to the db, incl. indexing it:
User.create = (data, callback) ->
  data.type="user"
  node = db.createNode(data)
  user = new User(node)
  node.save (err) ->
    return callback(err)  if err
    node.index "nodes", "type", "user", (err) ->
      return callback(err)  if err
      callback null, user

User.find_or_create_google_user = (google_user, callback) ->
  User.get_by_google_id google_user.id, (err, user) ->
    if err
      user_data=
        google_id: google_user.id
        email: google_user.emails[0]?.value
        username: google_user.displayName
        name: google_user.name?.familyName + " " + google_user.name?.givenName
      User.create user_data, (err2, user2)->
        return callback err,null if err2
        return callback null, user2
    else
      callback null, user

User.find_or_create_twitter_user = (twitter_user, callback) ->
  User.get_by_twitter_id twitter_user.id, (err, user) ->
    if err
      user_data=
        twitter_id: twitter_user.id
        email: twitter_user.emails[0]?.value
        username: twitter_user.displayName
        name: twitter_user.name?.familyName + " " + twitter_user.name?.givenName
      User.create user_data, (err2, user2)->
        return callback err, null if err2
        return callback null, user2
    else
      callback null, user

User.find_or_create_facebook_user = (facebook_user, callback) ->
  User.get_by_facebook_id facebook_user.id, (err, user) ->
    if err
      user_data=
        facebook_id: facebook_user.id
        email: facebook_user.emails[0]?.value
        username: facebook_user.displayName
        name: facebook_user.name?.familyName + " " + facebook_user.name?.givenName
      User.create user_data, (err2, user2)->
        return callback err, null if err2
        return callback null, user2
    else
      callback null, user

User.validateUser = (newUserAttributes, callback) ->
  errors = []
  errors.push 'No Email defined' unless newUserAttributes.email
  errors.push 'No Username defined' unless newUserAttributes.username
  errors.push 'No Password defined' unless newUserAttributes.password
  User.get_by_username newUserAttributes.username, (err, user) ->
    errors.push 'Username already taken' unless !user
    User.get_by_email newUserAttributes.email, (err, user) ->
      errors.push 'Email already taken' unless !user
      callback errors


User._get_by_property = (property, value, callback) ->
  query = "
    START n=node:nodes(type= \"user\")
    WHERE n.#{property} = \"#{value}\"
    RETURN n
  "
  db.query query, (err, results) ->
    return callback(err) if err
    return callback('no user found', null) if results.length == 0
    node = results[0] and results[0]["n"]
    callback null, new User(node)

