require 'sequel'
require './credentials'
require 'mysql2'
require './models'

db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)


p User[1].methods.sort