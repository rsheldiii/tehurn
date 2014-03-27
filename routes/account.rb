class Server < Sinatra::Application
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

	get "/account/logout" do
		check_authentication
		warden.logout
		redirect '/'
	end
end