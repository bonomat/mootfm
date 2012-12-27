# all we'll really store is the node; the rest of our properties will be
# derivable or just pass-through properties (see below).
Statement = module.exports = Statement = (@_node) ->

neo4j = require "neo4j"
async = require "async"

db = new neo4j.GraphDatabase(process.env.NEO4J_URL or "http://localhost:7474")

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
proxyProperty "type", true

Statement::_getFollowingRel = (other, callback) ->
  query = "
    START statement=node(#{@id}), other=node(#{other.id})
    MATCH (statement) -[rel]-> (other)
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


Statement::get_or_create_argue_point = (source,side,callback) ->
  @get_or_create_connection_point_by_type source,side, "arguepoint",callback

Statement::get_or_create_connection_point_by_type = (source,side,type,callback) ->
  #get existing connection
  query ="
    START startpoint=node(#{source.id}), statement=node(#{@id}), middle=node:nodes(type=\"votepoint\")
    MATCH startpoint --> middle --> statement
    WHERE has(middle.type) and middle.type=\"#{type}\" and has(middle.side) and middle.side = \"#{side}\"
    RETURN middle
    "
  db.query query, (err, results) =>
    return callback(err) if err
    if results.length>1
      #return callback null, results[0]["middle"]
      #TODO log a warning that there are db inconsistencies!
      return callback "DB inconsistent: Too many matching connections found in db:"+ results
    if results.length==1
      return callback null, results[0]["middle"]
    else
      connection = db.createNode({"type":type,"side":side})
      connection.save (err) =>
        return callback(err)  if err
        connection.index "nodes", "type", "votepoint", (err) =>
          return callback(err)  if err
          connection.createRelationshipTo @_node, "", {}, (err,rel)->
            return callback(err)  if err
            callback null, connection

Statement::argue = (other, side, callback) ->
  other.get_or_create_argue_point @_node,side,(err,arguepoint)=>
    return callback(err) if err
    @_node.createRelationshipTo arguepoint, "", {}, (err)->
      callback err

Statement::unargue = (other, side, callback) ->
  return callback("ERROR: not implemented")
  other.get_or_create_argue_point @_node,side,(err,arguepoint)=>
    return callback(err)  if err
    @_getFollowingRel arguepoint, (err, rel) ->
      return callback(err)  if err
      return callback(null)  unless rel
      rel.del (err)->
        callback(err)

Statement::getArguments = (callback) ->
  query ="
    START main=node(#{@id}), arguments=node:nodes(type=\"statement\"), vote=node:nodes(type=\"votepoint\")
    MATCH arguments --> vote --> main
    WHERE vote.type = \"arguepoint\" and arguments.type = \"point\"
    RETURN arguments, vote.side
    "
  db.query query, (err, results) =>
    return callback(err)  if err
    sides = {}
    i = 0
    side_list = (result["vote.side"] for result in results)
    for side in side_list when side
      sides[side]=[]
    for result in results
      sides[result["vote.side"]].push new Statement(result["arguments"])
    callback null, sides

# static methods:

Statement.get = (id, callback) ->
  db.getNodeById id, (err, node) ->
    return callback(err)  if err
    callback null, new Statement(node)

# creates the statement and persists (saves) it to the db, incl. indexing it:
Statement.create = (data, callback) ->
  data["type"]="point"
  node = db.createNode(data)
  statement = new Statement(node)
  node.save (err) ->
    return callback(err)  if err
    node.index "nodes", "type", "statement", (err) ->
      return callback(err)  if err
      callback null, statement


Statement.get_votes = (stmt, point, side, callback) ->
  # gets the user votes for points in regards to stmt
  stmt.get_or_create_argue_point point._node,side,(err,arguepoint)=>
    return callback(err) if err
    query = "
      START vote=node(#{arguepoint.id}), users=node:nodes(type=\"user\")
      MATCH users -[rel]-> vote
      WHERE users.type = \"user\" and users.type = \"user\" and has(rel.vote)
      RETURN sum(rel.vote)
      "
    db.query query,(err, results) =>
      return callback("DB error for get_votes: "+err) if err
      if results.length==1
        return callback null, results[0]["sum(rel.vote)"]
      else
        return callback null, 0

# creates a json compatible representation of this statement
Statement::get_representation = (level, callback) ->
  representation=
    title:@title
    id:@id
  return callback null, representation if level <= 0
  @getArguments (err, argument_dict) =>
    return callback(err) if err
    sides={}
    async.forEach ([side,stmt_arguments] for side, stmt_arguments of argument_dict), ([side,stmt_arguments],callback)=>
      async.map stmt_arguments, (argument,callback)=>
        argument.get_representation level-1, (err, representation)=>
          return callback(err) if err
          Statement.get_votes @,argument,side, (err, votes)=>
            return callback(err) if err
            representation.vote=votes
            callback null, representation
      , (err, side_arguments) ->
        return callback(err) if err
        sides[side]=side_arguments

        callback null
    , (err) ->
      return callback(err) if err
      representation["sides"]=sides
      callback null, representation

# creates a json compatible representation of this statement
Statement::get_all_points = (level, callback) ->
  console.log "level", level
  representation=
    title:@title
    id:@id
  return callback null, [representation] if level <= 0
  @getArguments (err, argument_dict) =>
    console.log "argument dic", argument_dict
    points=[representation]
    return callback(err) if err
    async.forEach ([side,stmt_arguments] for side, stmt_arguments of argument_dict), ([side,stmt_arguments],callback)=>
      console.log "for each"
      async.map stmt_arguments, (argument,callback)=>
        argument.get_all_points level-1, (err, points)=>
          return callback(err) if err
          Statement.get_votes @,argument,side, (err, votes)=>
            return callback(err) if err
            for point in points
              point.vote= votes
              point.side= side
            callback null, points
      , (err, side_arguments) ->
        return callback(err) if err
        console.log "old points", points
        points.push.apply(points, side_arguments)
        console.log "new points", points
        callback null
    , (err) ->
      console.log "final after async for each"
      return callback(err) if err
      callback null, points