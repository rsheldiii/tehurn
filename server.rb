require 'sinatra'
require 'warden'
require 'sequel'
require './credentials'
require './models'
require 'openurl'
require 'json'
require 'sinatra/flash'

#https://gist.github.com/nicholaswyoung/557436
#http://mikeebert.tumblr.com/post/27097231613/wiring-up-warden-sinatra

class Server < Sinatra::Application # I'll name it something else later
	#instantiates DB container
	
	db = Sequel.mysql2('tehurn', :host => 'localhost', :user => Credentials.username, :password => Credentials.password)
	#allows us to use cookies
	use Rack::Session::Cookie
	register Sinatra::Flash

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
				@streamer = StreamProfile.new(:name => channel["name"])
				@streamer.save
			else
				return false
			end
		end
		@streamer
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
		erb :edit_account
	end


	get '/account/details/edit/email' do
		check_authentication
		current_user.email = params['email']
		current_user.save
		JSON.generate({'success'=>'success'})
	end

	get '/search' do
		erb :search
	end

	get '/search/:q' do |q|
		"api to search for streamers names via q. regex?"
	end

	get '/login' do
		p flash[:error]
		erb :login, :locals =>{ :error => flash[:error]}
	end

	get "/logout" do
		check_authentication
		warden.logout
		redirect '/'
	end

	get 'register' do
		erb :register
	end

	get '/createuser' do
		if params[:email] and params[:password] and params[:password_confirmation] and params[:username]#todo: there's a better way to do this
			User.create(*parmas)#TODO: make sure this works
	end

	get '/verify' do
		"verification API call that renders either json or html based on some kind of input I havent figured out yet"
	end

	post "/session" do
	  warden.authenticate!
	  if warden.authenticated?
	    redirect "/account" 
	  else
	  	flash[:error] = "dead code wth"
	    redirect "/login"
	  end
	end

	post "/unauthenticated" do
		flash[:error] = "you are not authenticated"
		redirect "/login"
	end

	get '/:streamer' do |streamer|

		@streamer = checkOrCreateStreamer(streamer)

		if @streamer
			@count = @streamer.subscribers.count
		end

		p current_user.subscriptions
		p @streamer
		p current_user.subscriptions.include? @streamer

		erb :streamer, :locals => {:streamer => streamer, :user => current_user}
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
