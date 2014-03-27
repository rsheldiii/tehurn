class Server < Sinatra::Application

	#TODO: needs to go in helpers function, file, etc
	def checkOrCreateStreamer(streamer)
		@streamer = StreamProfile[:name => streamer]
		if @streamer.nil?
			#p 'https://api.twitch.tv/kraken/channels/'+streamer
			begin
				channel = JSON.parse(open('https://api.twitch.tv/kraken/channels/'+streamer).read())
			rescue
      			return false
    		end 

			if !channel["error"] and channel["name"]
				@streamer = StreamProfile.new(:name => channel["name"])
				@streamer.save
			else
				return false
			end
		end
		@streamer
	end

	get '/:streamer' do |streamer|

		@streamer = checkOrCreateStreamer(streamer)

		if @streamer
			@count = @streamer.subscribers.count
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
end