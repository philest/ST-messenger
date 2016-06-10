require 'httparty'

class FB
	include HTTParty
	debug_output $stdout
	GRAPH_URL = "https://graph.facebook.com/v2.6/me/messages"
	
	# TODO: refactor into a proc? 
	def self.send_pic(id, image)
		result = HTTParty.post(GRAPH_URL, 
			query: {access_token: ENV['FB_ACCESS_TKN']},
		    :body => { 
		    	recipient: {
		    		id: id
		    	},
		    	message: {
		    		attachment: {
		    			type: "image",
		    			payload: {
		    				url: image		
		    			}
		    		}
		    	}
		    }.to_json,
		    :headers => { 'Content-Type' => 'application/json' } )
		puts result
	end


	def self.send_txt(id, message)
		result = HTTParty.post(GRAPH_URL, 
			 query: {access_token: ENV['FB_ACCESS_TKN']}, 
		    :body => { 
		    	recipient: {
		    		id: id
		    	},
		    	message: {
		    		text: message
		    	}
		    }.to_json,
		    :headers => { 'Content-Type' => 'application/json' } )
	end
end
