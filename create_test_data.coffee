async = require "async"
Statement = require "./models/statement"

statement_data=
  title: "Apple is crap"
pro_statement_data=
  title: "Apple has child labour in China"
contra_statement_data=
  title: "Apple has best selling smart phone"
async.map [statement_data, pro_statement_data,contra_statement_data ], (item,callback)->
  Statement.create item, callback
, (err, [statement, pro_statement, contra_statement ]) ->
  return console.log(err) if err
  async.map [[pro_statement,"pro"],[contra_statement,"contra"] ], ([argument, side],callback)->
    argument.argue statement, side, callback
  , (err) ->
    return console.log(err) if err
    statement.get_representation (err, representation)->
      return console.log(err) if err
      console.log "Created Statement", representation