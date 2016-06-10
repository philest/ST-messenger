require 'spec_helper'
require 'birdv/fb_helper'

=begin 
# some example stubs!
#   https://github.com/bblimke/webmock

stub_request(:any, "www.example.com").
  to_return(body: "abc", status: 200,
    headers: { 'Content-Length' => 3 })

stub_request(:post, "www.example.com").
  with(body: "abc", headers: { 'Content-Length' => 3 })
=end

describe 'FBHelper' do

	let (:fb_caller) { Class.new{ include Birdv::FBHelper }.new }

	FB_URI  = "#{Birdv::FBHelper.get_graph_url}?access_token=#{ENV['FB_ACCESS_TKN']}"
	FAILURE = [{"error":{"message":"(#100) Invalid fbid.","type":"OAuthException","code":100,"fbtrace_id":"A0Nh+OHr+TX"}}, 400]
	SUCCESS = [{"recipient_id":"10209571935726081","message_id":"mid.1465592244050:7b2b9006d900596e93"}, 200]

	let (:stub_response ) do 
		lambda do |response, code| 
			stub_request(:any, FB_URI).
				to_return(body: response.to_s, status: code)
				#to_return(body: "abc", status: 400, headers: { 'Content-Length' => 3 })
		end
	end
	

	context 'fails to send text' do
		before do 
			stub_response.call(*FAILURE)
		end

		it 'returns the FB error code' do
			ret = fb_caller.send_txt('1','dummy message')
			expect(ret.body['error']).not_to be_empty
		end
	end


end