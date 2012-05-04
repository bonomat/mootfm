var neo4j = require('neo4j');
var db = new neo4j.GraphDatabase('http://localhost:7474');

function callback(err, result) {
    if (err) {
        console.error(err);
    } else {
        console.log(result);    // if an object, inspects the object
    }
}
