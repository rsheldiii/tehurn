	require 'sequel'
require './credentials'
require 'mysql2'
require './models'

#NOTE: THIS IS DESTRUCTIVE. DO NOT RUN IF THERE IS DATA PRESENT

db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)

p "creatings users table"
db.create_table! :users do
	primary_key :id
	String      :username, :null => false
	String 		:email, :null => false
	String		:password_digest
	#foreign_key	:streamer_id

	index 		:email
	index		:username
end

p "creating streamers table"
db.create_table! :stream_profiles do
	primary_key :id
	String 		:name, :null => false
	foreign_key :user_id
	boolean 	:activated, :default => false
end

p "creating subscriber to subscription association table"
db.create_table! :subscribers_subscriptions do
	foreign_key :user_id
	foreign_key :stream_profile_id
end


#example content
p "creating bob"
bob = User.create(:username => "bob", :email => "rsheldiii@gmail.com", :password => "foo",  :password_confirmation => "foo")

p "creating sig user"
sig_user = User.create(:username => "sig", :email => 'sig@sig.sig', :password => "bar", :password_confirmation => 'bar')

p "creating sig profile"
sig = StreamProfile.create(:name => "siglemic")

p "sig user methods"
p sig_user.methods.sort

p "sig profile methods"
p p sig.methods.sort

p "adding sig profile to sig user"
sig_user.add_stream_profile sig

p "subscribing bob to sig"
bob.add_subscription sig
#sig.add_subscriber bob

bob.save
sig.save
sig_user.save

p sig.user