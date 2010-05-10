#
# http://www.mongodb.org/display/DOCS/Ruby+Tutorial
#
require "rubygems"
require "mongo"
require 'pp'

db = Mongo::Connection.new("localhost").db("mydb")
collection = db["testCollection"]

puts "count = " + collection.count().to_s

puts '-' * 30 + ' search all'
collection.find().each do |row|
  pp row
end

puts '-' * 30 + ' Search with a Query'
collection.find("type" => 'database').each do |row|
  # puts row.class # OrderedHash
  pp row
end

puts '-' * 30 + ' Search with regexp'
collection.find("name" => /ch/).each do |row|
  pp row
end

