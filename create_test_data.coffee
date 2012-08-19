async = require "async"
Statement = require "./models/statement"
User = require './models/user'

statement_data=
  title: "Apple is crap"
pro_statement_data=
  title: "Apple has child labour in China"
pro2_statement_data=
  title: "Apple is against open source"
contra_statement_data=
  title: "Apple has best selling smart phone"
pro_lv2_statement_data=
  title: "2 billion iPhones sold"
async.map [statement_data, pro_statement_data,pro2_statement_data,contra_statement_data,pro_lv2_statement_data ], (item,callback)->
  Statement.create item, callback
, (err, [statement, pro_statement,pro2_statement, contra_statement,pro_lv2_statement ]) ->
  return console.log(err) if err
  async.map [[pro_statement,"pro"],[pro2_statement,"pro"],[contra_statement,"contra"] ], ([argument, side],callback)->
    argument.argue statement, side, callback
  , (err) ->
    return console.log(err) if err
    pro_lv2_statement.argue contra_statement, "pro", (err, callback) ->
      user_data=
        name: "Tobias Hönisch"
        email: "tobias@hoenisch.at"
        password: "ultrasafepassword"
      User.create user_data, (err, user)->
        user.vote statement, pro_statement, "pro", 1, (err,total_votes)=>
          user.vote contra_statement, pro_lv2_statement, "pro", -1, (err,total_votes)=>

            statement.get_representation 2, (err, repr)->
              return console.log(err) if err
              console.log "Created Statement", JSON.stringify(repr, null, 2)