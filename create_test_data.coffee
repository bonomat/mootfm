async = require "async"
Statement = require "./models/statement"

statement_data=
  title: "Apple is crap"
pro_statement_data=
  title: "Apple has child labour in China"
contra_statement_data=
  title: "Apple has best selling smart phone"
pro_lv2_statement_data=
  title: "2 billion iPhones sold"
async.map [statement_data, pro_statement_data,contra_statement_data,pro_lv2_statement_data ], (item,callback)->
  Statement.create item, callback
, (err, [statement, pro_statement, contra_statement,pro_lv2_statement ]) ->
  return console.log(err) if err
  async.map [[pro_statement,"pro"],[contra_statement,"contra"] ], ([argument, side],callback)->
    argument.argue statement, side, callback
  , (err) ->
    return console.log(err) if err
    pro_lv2_statement.argue contra_statement, "pro", (err, callback) ->

      async.map [statement, contra_statement], (stmt, callback)->
        stmt.get_representation callback
      , (err, [statement_repr, contra_repr ]) ->
        return console.log(err) if err
        console.log "Created Statement", JSON.stringify(statement_repr)
        console.log "Created Statement", JSON.stringify(contra_repr)