DaoMongo = (cfg, conn, log, cache) ->
  throw new Error("Config and connection vars,  and log function are required.")  if not cfg or not conn or not log
  @config = cfg
  @connection = conn
  @log = log
  @models = {}
  @cache = cache
  
uuid = require("node-uuid")
mongoose = require("mongoose")
util = require("util")
helper = require("../helper")
dateformat = require("dateformat")
DaoMongo::registerModel = (itemClass) ->
  that = this
  modelName = helper.capitalize(itemClass.entityName + "MongoModel")
  @models[modelName] = new mongoose.Schema(itemClass.entitySchema)

DaoMongo::create = (item, callback) ->
  that = this
  created = dateformat("yyyy-mm-dd HH:MM:ss")
  item_id = uuid()
  if item
    item[item.getEntityIndex()] = item_id
    item[item.getEntityCreated()] = created
    modelName = helper.capitalize(item.getEntityName() + "MongoModel")
    NeededMongoModel = @connection.model(modelName, @models[modelName])
    m = new NeededMongoModel()
    propNames = item.getPropNamesAsArray()
    i = 0

    while i isnt propNames.length
      m[propNames[i]] = item[propNames[i]]
      i++
    that.log util.inspect(m)
    m.save (err) ->
      if err
        that.log "Error: create(): " + err
      else if that.cache
        that.cache.putItem item
        that.cache.delItems item.getClass()
      callback false, item  if callback
      item
  else
    @log "Error: create(): cannot save item"
    callback true, null  if callback
    null

DaoMongo::update = (item, callback) ->
  that = this
  created = dateformat("yyyy-mm-dd HH:MM:ss")
  if item
    modelName = helper.capitalize(item.getEntityName() + "MongoModel")
    NeededMongoModel = @connection.model(modelName, @models[modelName])
    itemId = (item.asArray())[0]
    findObj = {}
    findObj[item.getEntityIndex()] = itemId
    propNames = item.getPropNamesAsArray()
    slicedFields = propNames.slice(-propNames.length + 1)
    updateObj = {}
    i = 0

    while i isnt slicedFields.length
      updateObj[slicedFields[i]] = item[slicedFields[i]]
      i++
    @log "update(): " + JSON.stringify(findObj)
    @log "update(): " + JSON.stringify(updateObj)
    options = {}
    NeededMongoModel.update findObj,
      $set: updateObj
    , options, (err) ->
      if err
        that.log "Error: update(): " + err
      else if that.cache
        that.cache.putItem item
        that.cache.delItems item.getClass()
      callback false, item  if callback
      item
  else
    @log "Error: update(): cannot update item"
    callback true, null  if callback
    null

DaoMongo::list = (itemClass, propNames, callback) ->
  that = this
  if @cache
    @cache.getItems itemClass, (cachedErr, cachedResult) ->
      if cachedErr or not cachedResult
        modelName = helper.capitalize(itemClass.entityName + "MongoModel")
        NeededMongoModel = that.connection.model(modelName, that.models[modelName])
        query = NeededMongoModel.find({})
        query.execFind (err, results) ->
          if err
            that.log "Error: list(): " + err
          else that.cache.putItems itemClass, results  if that.cache
          callback false, results  if callback
          results
      else
        callback false, cachedResult  if callback
        cachedResult

DaoMongo::get = (itemClass, itemId, callback) ->
  that = this
  if @cache
    @cache.getItem itemClass, itemId, (cachedErr, cachedResult) ->
      if cachedErr or not cachedResult
        modelName = helper.capitalize(itemClass.entityName + "MongoModel")
        NeededMongoModel = that.connection.model(modelName, that.models[modelName])
        findObj = {}
        findObj[itemClass.entityIndex] = itemId
        NeededMongoModel.findOne findObj, (err, result) ->
          if err
            that.log "Error: get(): " + err
          else that.cache.putItemByClass itemClass, result  if that.cache
          callback false, result  if callback
          result
      else
        callback false, cachedResult  if callback
        cachedResult

DaoMongo::remove = (itemClass, itemId, callback) ->
  that = this
  modelName = helper.capitalize(itemClass.entityName + "MongoModel")
  NeededMongoModel = @connection.model(modelName, @models[modelName])
  findObj = {}
  findObj[itemClass.entityIndex] = itemId
  NeededMongoModel.remove findObj, (err, result) ->
    if err
      that.log "Error: remove(): " + err
    else if that.cache
      that.cache.delItem itemClass, itemId
      that.cache.delItems itemClass
    callback false, result  if callback
    result

module.exports.DaoMongo = DaoMongo
