require 'httparty'
module Birdv
	module FBHelper
		# this is not a public API
		
		include HTTParty	

		#debug_output $stdout
		
		GRAPH_URL = "https://graph.facebook.com/v2.6/me/messages"

		def self.get_graph_url
			GRAPH_URL
		end
		
		# TODO: refactor into a proc? 
		def send_pic(id, image)
			HTTParty.post(GRAPH_URL, 
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
		end

		# TODO: what is the body of a complete 400 error?
		def send_txt(id, message)
			HTTParty.post(GRAPH_URL, 
				 query: {access_token: ENV['FB_ACCESS_TKN']}, 
			    :body => { 
			    	recipient: {
			    		id: id
			    	},
			    	message: {
			    		text: message
			    	}
			    }.to_json,
			    :headers => { 'Content-Type' => 'application/json' })
		end
	end
end