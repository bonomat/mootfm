module.exports = class Dispatcher
  constructor: () ->
    @user_pages={}

  register: (user, page_id,callback)->
    if page_id in @user_pages
      @user_pages[page_id].push(user)
    else
      @user_pages[page_id]=[user]
    callback()

  unregister: (user, page_id,callback)->
    if page_id in @user_pages
      users = @user_pages[page_id]
      index = users.indexOf user
      users.splice index,1
    
    callback()

  send_to_user: (stmt, user, callback)->
    user.socket.emit "statement", [stmt]
    callback()

  dispatchOne: (stmt, callback)->
    page_ids=[stmt.id]
    page_ids.push stmt.parent if stmt.parent
    for page_id in page_ids
      users=@user_pages[page_id]
      async.forEach users, (user,callback)=>
        @send_to_user stmt, user,callback
      , (err)->
        return callback()

  dispatch: (stmts,callback) ->
    async.forEach stmts, dispatchOne, callback

