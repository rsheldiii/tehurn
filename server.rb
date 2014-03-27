require 'sinatra'
require 'warden'
require 'sequel'
require './credentials'
require './models'
require 'open-uri'
require 'json'
require 'sinatra/flash'
include ERB::Util

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

	before do
		@user = current_user || false;
		if flash[:error]
			@error = flash[:error]
		end
		if flash[:success]
			@success = flash[:success]
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

	get 'register' do
		erb :register
	end

	post '/createuser' do
		if params[:email] and params[:password] and params[:password_confirmation] and params[:username]#todo: there's a better way to do this
			User.create(*params)#TODO: make sure this works
		end
	end

	get '/verify/:code' do |code|
		user = User[:code => code]
		if user
			user.verified = true
			user.save
			flash[:success] = "congratulations, your account has been verified! you should now be able to login"
		else
			flash[:error] = "I'm sorry, I couldnt find the user assigned to that code"
		end
		redirect '/'
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

	require './routes/account'
	require './routes/streamer'

	run!
end
