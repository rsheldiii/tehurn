require 'sinatra'
require 'warden'
require 'sequel'
require './credentials'
require './models'
require 'openurl'
require 'json'

#https://gist.github.com/nicholaswyoung/557436
#http://mikeebert.tumblr.com/post/27097231613/wiring-up-warden-sinatra
db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)


class Server < Sinatra::Application # I'll name it something else later
	#instantiates DB container
	
	db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)
	#allows us to use cookies
	use Rack::Session::Cookie

	#configures Warden as middleware
	use Warden::Manager do |manager|
	  manager.default_strategies :password
	  manager.failure_app = Server
	  manager.serialize_into_session {|user| user.id}
	  manager.serialize_from_session {|id| User[id]}
	end

	#apparently warden is picky so this is a requirement
	Warden::Manager.before_failure do |env,opts|
	  env['REQUEST_METHOD'] = 'POST'
	end

	#defining strategy we accessed earlier
	Warden::Strategies.add(:password) do
	  def valid?
	    params["email"] || params["password"]
	  end
	 
	  def authenticate!
	  	db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)#TODO: get rid of this
	    user = User[:email => params["email"]]
	    if user && user.authenticate(params["password"])
	      success!(user)
	    else
	      fail!("Could not log in")
	    end
	  end
	end

	def warden
	    env['warden']
	end

	def current_user
	    warden.user
	end

	def check_authentication
	    redirect '/login' unless warden.authenticated?
	end

	def checkOrCreateStreamer(streamer)
		@streamer = StreamProfile[:name => streamer]
		if @streamer.nil?
			channel = JSON.parse(open('https://api.twitch.tv/kraken/channels/'+streamer))

			if !channel["error"] and channel["name"]
				newstream = StreamProfile.new(:name => channel["name"])
				newstream.save
			else
				return false
			end
		else
			streamer
		end
	end


	#actual pages

	get '/' do
		@streams = db["""
			SELECT stream_profiles.name
			FROM stream_profiles 
			INNER JOIN subscribers_subscriptions 
				ON stream_profiles.id = subscribers_subscriptions.stream_profile_id 
			INNER JOIN users 
				ON users.id = subscribers_subscriptions.user_id 
			GROUP BY stream_profiles.name 
			ORDER BY COUNT(users.id)
			LIMIT 10;"""]

		p @streams
		erb :index
	end

	get '/favicon.ico' do end

	get '/account' do
		check_authentication
		p session
		p current_user

		erb :account, :locals => {:user => current_user}
	end

	get '/account/list' do
		check_authentication
		"API call to list all streamers for current session. used by /account"
	end

	get '/account/details' do
		check_authentication
		"API call to list all details of current session"
	end

	get '/account/details/edit' do
		check_authentication
		"boilerplate page to list all details and provide buttons to edit them. currently only email"
	end


	get '/account/details/edit/email' do
		check_authentication
		"POST or is it PUT? API call to edit email attribute to whatever is in $_POST[email]"
	end

	get '/search' do
		"boilerplate, search page with no actual content"
	end

	get '/search/:q' do |q|
		"api to search for streamers names via q. regex?"
	end

	get '/login' do
		erb :login
	end

	get "/logout" do
		check_authentication
		warden.logout
		redirect '/'
	end

	get '/register' do
		"registration API call. creates unverified account"
	end

	get '/verify' do
		"verification API call that renders either json or html based on some kind of input I havent figured out yet"
	end

	post "/session" do
	  warden.authenticate!
	  if warden.authenticated?
	    redirect "/account" 
	  else
	    redirect "/login"
	  end
	end

	post "/unauthenticated" do
		redirect "/login"
	end

	get '/:streamer' do |streamer|
		"shows the streamer's twitch.tv and a button to subscribe"

		@streamer = checkOrCreateStreamer(streamer)

		if @streamer
			@count = @streamer.subscribers.count
		end

		if session[:user_id]
			@user = User[session[:user_id]]
		else
			@user = false
		end

		erb :streamer, :locals => {:streamer => streamer}
	end

	get '/:streamer/subscribe' do |streamer|
		check_authentication
		streamer = StreamProfile[:name => streamer]
		if !streamer.nil?
			current_user.add_subscription streamer
			current_user.save
			JSON.generate({'success'=>'success'})
		else
			JSON.generate({'error'=>'streamer does not exist'})
		end
	end

	get '/:streamer/unsubscribe' do |streamer|
		check_authentication
		streamer = StreamProfile[:name => streamer]
		if !streamer.nil?
			current_user.remove_subscription streamer
			current_user.save
			JSON.generate({'success'=>'success'})
		else
			JSON.generate({'error'=>'streamer does not exist'})
		end
	end

	get ':streamer/pm' do |streamer|
		redirect "http://www.twitch.tv/message/compose?to="+streamer
	end

	run!
end
