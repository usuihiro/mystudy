#
# http://www.mongodb.org/display/DOCS/Ruby+Tutorial
#
require "rubygems"
require "mongo"
require 'pp'

db = Mongo::Connection.new("localhost").db("mydb")
collection = db["testCollection"]

docs = [
  {"name" => "MongoDB", "type" => "database", "count" => 10,
   "info" => {"x" => 203, "y" => '102'}},
  {"name" => "CouchDB", "type" => "database", "count" => 1,
   "info" => {"x" => 203, "y" => '102'}},
  {"name" => "Apache", "type" => "webserver", "count" => 7,
   "info" => {"x" => 203, "y" => '102'}}
]

# create index
collection.create_index("type")

docs.each do |doc|
  pp doc
  collection.insert(doc)
end
