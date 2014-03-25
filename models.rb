require 'sequel_secure_password'

db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)

class User < Sequel::Model
	plugin :secure_password
	one_to_one :streamer
	many_to_many :subscriptions, :class => :Streamer, :left_key => :user_id, :right_key => :streamer_id, :join_table => :streamers_users
end

class Streamer < Sequel::Model
	one_to_one :user
	many_to_many :subscribers, :class => :User, :left_key => :streamer_id, :right_key => :user_id, :join_table => :streamers_users
end