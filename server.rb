require 'sinatra'
require 'warden'

#https://gist.github.com/nicholaswyoung/557436
#http://mikeebert.tumblr.com/post/27097231613/wiring-up-warden-sinatra


use Rack::Session::Cookie

#actual pages to visit

	#requires auth

get '/account' do
	"account boilerplate page. shows all streamers subscribed to with an unsubscribe button based on session, and all info, with a link to edit"
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

	#does not require auth

get '/index' do
	"boilerplate showing most popular streamers and login screen and search bar"
end

get '/search' do
	"boilerplate, search page with no actual content"
end

get '/:streamer' do |streamer|
	"shows the streamer's twitch.tv and a button to subscribe"
end

#api calls

	#requires auth
get '/:streamer/subscribe' do |streamer|
	"API call to sign up to a certain streamer"
end

get '/:streamer/unsubscribe' do |streamer|
	"API call to unsubscribe to streamer"
end

	#does not require auth

get '/search/:q' do |q|
	"api to search for streamers names via q. regex?"
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

#misc

get 'pm/:streamer' do |streamer|
	"redirects to link to pm streamer if Twitch has that functionality"
end