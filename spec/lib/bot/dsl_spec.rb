require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'

describe Birdv::DSL::StoryTimeScript do

	let (:script_obj) { Birdv::DSL::StoryTimeScript.new('examp') do end }

	around(:all) do
		DatabaseCleaner.clean_with(:truncation)
	end

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
		before(:each) do
			@num_pages 		= 2;
			@txt  			= "hey this is window text, which can be much longer than button text"
			@lib 			= 'day1'
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

		it 'sends a send_story!', story: true do
			expect {
				script_obj.send( 
					@aubrey, 
					script_obj.send_story({ 
									recipient:  @aubrey,
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
		
		# TODO: explain this test
		it 'does not error when passed json, but doesn\'t contain json' do


		end

	end
	
	# Visual separation :P
	# => 
	# => 
	# =>
	# note the difference between 'send story...' and 'send send_story'.
	# the former is usually used in a script, the latter not
	context '#send a #story' do
		it 'expects certain arguments' do

		end

		it 'send correct story when ' do

		end

		it 'updates the last_story_read field' do

		end


	end



	# Visual separation :P
	# => 
	# => 
	# =>
	# the success of these tests is verified by making the corrext HTTP request
	context 'name replacement stuff', text_replace: true do
		before(:all) do
			@txt = "__PARENT__||__CHILD__||__TEACHER__"
			@lib 				= 'day1'
			@title 			= 'chomp'
			@aubrey 	= '10209571935726081' # aubrey
			@estohb = lambda do |text|  
				success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
				stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
		         with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"text\":\"#{text}\"}}",
		              :headers => {'Content-Type'=>'application/json'}).
		         to_return(:status => 200, :body => @success, :headers => {})			
			end
		end

		# after(:each) do
		# 	DatabaseCleaner.clean_with(:truncation)
		# end

		it 'has no problem the the user is missing first_name' do
			# stub the request with the expected body :)
			@estohb.call '||Lil||Mr. McEsterWahl'
			u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey
			t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
			t.add_user u
			User.where(fb_id:@aubrey).first.update first_name: nil
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error				
		end

		it 'has no problem the the user is missing last_name' do
			@estohb.call 'Aubrey||Lil||Mr. McEsterWahl'
			u = User.create  child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
			t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
			t.add_user u
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error	
		end

		it 'has no problem the the user is missing last/first_name' do
			@estohb.call '||Lil||Mr. McEsterWahl'
			u = User.create child_name:'Lil Aubs', fb_id: @aubrey
			t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
			t.add_user u			
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error	
		end

		it 'renders the teacher, parent, and child names when all set' do
			@estohb.call 'Aubrey||Lil||Mr. McEsterWahl'
			u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
			t = Teacher.create email:'poop@pee.com', signature: "Mr. McEsterWahl"
			t.add_user u			
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error	
		end

		it 'properly render just the child name, nothing else set' do
			@estohb.call '||Lil||StoryTime'
			u = User.create child_name:'Lil Aubs', fb_id: @aubrey
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error	
		end

		it 'works when user has not teacher' do
			@estohb.call 'Aubrey||Lil||StoryTime'
			u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error	
		end		
		it 'works when teacher has no signature' do
			@estohb.call 'Aubrey||Lil||StoryTime'
			u = User.create last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey, first_name:'Aubrey'
			t = Teacher.create email:'poop@pee.com', signature: nil
			t.add_user u			
			expect {
				script_obj.send(
					@aubrey,
					script_obj.text({ text: @txt })
				)
			}.not_to raise_error	
		end				
	end	


	context 'when #send, the DB should be updated' do
		before(:all) do

			#load curriculae
			dir = "#{File.expand_path(File.dirname(__FILE__))}/test_curricula/"
			Birdv::DSL::Curricula.load(dir, absolute=true)			

			# load a script
			@cli = Birdv::DSL::ScriptClient
			@cli.new_script 'day1' do
				button_story({
					name: 		'tap_here',
					title: 		"You're next story's coming soon!",
					image_url:'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
					buttons: 	[postback_button('Tap here!', script_payload(:scratchstory))]
				})
				button_normal({
					name: 			 'thanks',
					window_text: "__TEACHER__: I’ll send another story tomorrow night :)",
					buttons: 			[postback_button('Thank you!', script_payload(:yourwelcome))]
				})			
				sequence 'firsttap' do |recipient|
					txt = "__TEACHER__: Hi __PARENT__, here’s another story!"
					send recipient, text({text:txt})
					send recipient, button({name:'tap_here'}) 
				end
				sequence 'scratchstory' do |recipient|
					send recipient, story 
					img_1 = "https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg"
					send recipient, picture({url:img_1})
					send recipient, button({name: 'thanks'})
				end
				sequence 'yourwelcome' do |recipient|
					send recipient, text({text: "You're welcome :)"})
				end					
			
			end #=>END @cli.new_script 'day1' do

			@s = @cli.scripts

		end #=>END before(:all) do

		it 'updates last sequence seen' do
			# expect {

			# }.to.change(@u.state_table.last_sequence_seen).to eq()
		end

		it 'updates last_script_sent_time when :init sequence' do

		end

		it 'does not update last_sequence_seen when not :init sequence' do

		end

		it 'updates story read when sequence' do

		end
	end #=>END context 'when #send, the DB should be updated' do
end
