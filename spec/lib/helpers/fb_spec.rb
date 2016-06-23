require 'spec_helper'
require 'helpers/fb'

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
	before(:all) do
		WebMock.disable_net_connect!(allow_localhost:true)
	end

	# facebook url, i.e. 'https://graph.facebook.com/v2.6/me/messages?access_token=blahblahblah'
	FB_URI  = "#{Facebook::Messenger::Helpers.get_graph_url}?access_token=#{ENV['FB_ACCESS_TKN']}"

	# stub HTTP responses from facebook
	FAILURE = [{"error":{"message":"(#100) Invalid fbid.","type":"OAuthException","code":100,"fbtrace_id":"A0Nh+OHr+TX"}}, 400]
	SUCCESS = [{"recipient_id":"10209571935726081","message_id":"mid.1465592244050:7b2b9006d900596e93"}, 200]

	DUMMY_MSG = ["some FB ID", "this is a generic message"]

	# a mock instance of a class that has FBHelper functions
	let (:fb_caller) { Class.new{ include Facebook::Messenger::Helpers }.new }

	# a reusable wrapper for #stub_request from webmock
	let (:stub_response ) do 
		lambda do |response, code| 
			stub_request(:any, FB_URI).to_return(body: response.to_s, status: code)
		end
	end	

	context 'text message fails' do
			before(:example) do 
				stub_response.call(*FAILURE)
			end

			it 'returns the FB error code' do
				ret = fb_caller.fb_send_txt(*DUMMY_MSG)
				expect(ret.body['error']).not_to eq(nil)
			end
	end

	context 'text message succeeds' do
			before(:example) do 
				stub_response.call(*SUCCESS)
			end

			it 'does not return FB error code' do
				ret = fb_caller.fb_send_txt(*DUMMY_MSG)
				expect(ret.body['error']).to eq(nil)
			end

			it 'has a recipient_id' do
				ret = fb_caller.fb_send_txt(*DUMMY_MSG)
				expect(ret.body['recipient_id']).not_to eq(nil)
			end
	end
end