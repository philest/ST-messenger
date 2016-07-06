require 'spec_helper'
require 'bot/dsl'

describe Birdv::DSL::StoryTimeScript do

	let (:script_obj) {Birdv::DSL::StoryTimeScript.new('examp') do end}
	
	before(:each) do

		@pb         = script_obj.postback_button('Tap here!', 'dumb_payload')
		@ubt  			= script_obj.url_button('Tap here!', 'http://example.com')

	end

	# => # => # => # => 
	# => # => # => # => 
	# => # => # => # => 
	# => # => # => # => 
	context '#button_story' do
		before(:all) do
			@btn_name = 'poop'
		end

		it 'hash has required properties' do
			btn = script_obj.button_story ({
				name: @btn_name, 
				title: 'my title',
				image_url: "b", 
				subtitle:"c",
				buttons: [@pb, @ubt]
				})

			[:title, :image_url, :subtitle].each do |x|
				expect(btn[:message][:attachment][:payload][:elements][0].key? x).to be true
			end
		end

		it 'registers newly made button' do
			btn = script_obj.button_story ({
				name: @btn_name, 
				image_url: "b", 
				title: 'my title',
				subtitle:"c",
				buttons: [@pb, @ubt]
				})			
			expect(script_obj.button(@btn_name)).to eq(btn)
		end

		it 'does not err when buttons not set' do
			expect{
				script_obj.button_story({
				name:'garbage',
				title: 'poop',
				image_url: "b"			
				}
			)}.not_to raise_error
		end

		context 'when stuff is not set properly, raises an error' do
			it 'raises an error if title not set properly, no buttons' do
				expect{
					script_obj.button_story({
					name:'garbage',
					image_url: "b"			
					}
				)}.to raise_error(ArgumentError)
			end

			it 'raises an error if title and image_url not set properly, no buttons' do
				expect{
					script_obj.button_story({
					name:'garbage'		
					}
				)}.to raise_error(ArgumentError)
			end

			it 'raises an error if title not set properly, with buttons' do
				expect{
				script_obj.button_story ({
				name: @btn_name, 
				image_url: "b", 
				subtitle:"c",
				buttons: [@pb, @ubt]
				})}.to raise_error(ArgumentError)
			end
		end
	end

	# Visual separation :P
	# => # => # => # => 
	# => # => # => # => 
	# => # => # => # => 
	context '#button_normal' do
		before(:all) do
			@btn_name = 'btn_normal_test'
			@txt  = "hey this is window text, which can be much longer than button text"
		end

		it 'hash has required properties' do
			btn = script_obj.button_normal({
				name: @btn_name, 
				window_text: @txt,
				buttons: [@pb, @ubt]
				})
			[:text, :buttons].each do |x|
				expect(btn[:message][:attachment][:payload].key? x).to be true
			end

			expect(btn[:message][:attachment][:payload][:template_type]).to eq 'button'
		end

		it 'registers newly made button' do
			btn = script_obj.button_normal({
				name: @btn_name, 
				window_text: @txt,
				buttons: [@pb, @ubt]
			})			
			expect(script_obj.button(@btn_name)).to eq(btn)
		end

		it 'raises error when buttons not set' do
			expect{
				script_obj.button_normal({
				name: @btn_name,
				window_text: @txt,
				}
			)}.to raise_error
		end

		it 'raises an error if title & buttons not set properly' do
			expect{
				script_obj.button_normal({
				name: @btn_name,
				}
			)}.to raise_error(ArgumentError)
		end
	end


	# Visual separation :P
	# => 
	# => 
	# =>
	context '#send' do
		before(:all) do
			@num_pages 	= 2;
			@txt  			= "hey this is window text, which can be much longer than button text"
			@lib 				= 'day1'
			@title 			= 'chomp'
			

			@aubrey 	= '10209571935726081' # aubrey 
			User.create first_name:'Aubrey', last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey
		end

		before(:example, :story) do
			success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
			# one stub per page
			@num_pages.times do |i|
	      stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
	        with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"image\",\"payload\":{\"url\":\"https://s3.amazonaws.com/st-messenger/#{@lib}/#{@title}/#{@title}#{i+1}.jpg\"}}}}",
	            :headers => {'Content-Type'=>'application/json'}).
	        to_return(:status => 200, :body => success, :headers => {})
	    end
		end

		before(:example, :text) do
			success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
			stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
         with(:body => "{\"recipient\":{\"id\":\"#{@aubrey}\"},\"message\":{\"text\":\"#{@txt}\"}}",
              :headers => {'Content-Type'=>'application/json'}).
         to_return(:status => 200, :body => success, :headers => {})
		end		

		it 'sends a story!', story: true do
			expect {
				script_obj.send( 
					@aubrey, 
					script_obj.story({ 
									library: 		@lib,
									title: 	 		@title,
									num_pages: 	@num_pages,
								})
					)
			}.not_to raise_error
		end

		it 'sends a text', text: true do
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt
						})
				)
			}.not_to raise_error
		end

		it 'has no problem the the user is missing first_name' do


		end

		it 'has no problem the the user is missing last_name' do


		end

		it 'has no problem the the user is missing last/first_name' do


		end

		it 'properly renders the teacher, parent, and child names' do

		end

		it 'properly render just the child name' do

		end

	end

	context '#run_sequence' do


	end

	context '#button' do
		it 'returns json when argument is string' do

		end

		it 'returns json when argument is hash' do

		end
	end

	context '#text' do
		it 'hash has required propterties' do

		end
	end

	context '#picture' do
		it 'hash has required propterties' do

		end
	end


end