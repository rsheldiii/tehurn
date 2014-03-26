require 'sequel_secure_password'

db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)

class User < Sequel::Model
	plugin :secure_password
	one_to_many :stream_profile
	many_to_many :subscriptions, :class => :StreamProfile, :left_key => :user_id, :right_key => :stream_profile_id, :join_table => :subscribers_subscriptions
end

class StreamProfile < Sequel::Model
	many_to_one :user
	many_to_many :subscribers, :class => :User, :left_key => :stream_profile_id, :right_key => :user_id, :join_table => :subscribers_subscriptions
end