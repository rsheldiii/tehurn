require 'sequel'
require 'credentials'

DB = Sequel.mysql('tehurn' :host=>'localhost', :)