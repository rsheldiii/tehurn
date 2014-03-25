require 'sequel'
require './credentials'
require 'mysql2'
require './models'

#NOTE: THIS IS DESTRUCTIVE. DO NOT RUN IF THERE IS DATA PRESENT

db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)

db.create_table! :users do
	primary_key :id
	String      :name
	String 		:email
	String		:password_digest
	#foreign_key	:streamer_id

	index 		:email
	index		:name
end

db.create_table! :streamers do
	primary_key :id
	foreign_key :user_id
	boolean 	:activated, :default => false
end

db.create_table! :streamers_users do
	foreign_key :user_id
	foreign_key :streamer_id
end


#example content

bob = User.create(:name => "bob", :email => "bob@bob.bob", :password => "foo",  :password_confirmation => "foo")
sig_user = User.create(:name => "sig", :email => 'sig@sig.sig', :password => "bar", :password_confirmation => 'bar')
sig = Streamer.create()
sig_user.streamer = sig
#sig.user = sig_user

bob.add_subscription sig
#sig.add_subscriber bob

bob.save
sig.save
sig_user.save

p sig.user