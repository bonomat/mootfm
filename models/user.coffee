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

# creates the statement and persists (saves) it to the db, incl. indexing it:
User.create = (data, callback) ->
  node = db.createNode(data)
  user = new User(node)
  node.save (err) ->
    return callback(err)  if err
    node.index INDEX_NAME, INDEX_KEY, INDEX_VAL, (err) ->
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
    START n=node:#{INDEX_NAME}(#{INDEX_KEY}= \"#{INDEX_VAL}\")
    WHERE n.#{property} = \"#{value}\"
    RETURN n
  "
  db.query query, (err, results) ->
    return callback(err) if err 
    return callback('no user found', null) if results.length == 0
    node = results[0] and results[0]["n"]
    callback null, new User(node)

