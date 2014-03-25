require 'sinatra'
require 'warden'

use Rack::Session::Cookie

get '/index' do
	"boilerplate showing most popular streamers and login screen and search bar"
end

get '/search' do
	"boilerplate, search page with no actual content"
end

get '/account' do
	"account boilerplate page. shows all streamers subscribed to with an unsubscribe button based on session, and all info, with a link to edit"
end

get '/:streamer' do |streamer|
	"shows the streamer's twitch.tv and a button to subscribe"
end

get '/:streamer/subscribe' do |streamer|
	"API call to sign up to a certain streamer"
end

get '/:streamer/unsubscribe' do |streamer|
	"API call to unsubscribe to streamer"
end

get '/search/:q' do |q|
	"api to search for streamers names via q. regex?"
end

get '/account/list' do
	"API call to list all streamers for current session. used by /account"
end

get '/account/details' do
	"API call to list all details of current session"
end

get '/account/details/edit' do
	"boilerplate page to list all details and provide buttons to edit them. currently only email"
end

get '/account/details/edit/email' do
	"POST or is it PUT? API call to edit email attribute to whatever is in $_POST[email]"
end

get '/register' do
	"registration API call. creates unverified account"
end

get 'verify' do
	"verification API call that renders either json or html based on some kind of input I havent figured out yet"
end

get 'pm/:streamer' do |streamer|
	"redirects to link to pm streamer if Twitch has that functionality"
end