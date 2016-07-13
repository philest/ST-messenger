require 'spec_helper'
require 'bot/dsl'
require 'bot/curricula'

describe Birdv::DSL::StoryTimeScript do


	let (:script_obj) {Birdv::DSL::StoryTimeScript.new('examp') do end}
	
	before(:all) do
		ENV['CURRICULUM_VERSION'] = "0" 	# for the purposes of this spec
		@aubrey 	= '10209571935726081' # aubrey 
		@success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"

		@stub_story = lambda do |recipient, lib, title, num_pages|
			num_pages.times do |i|
	      stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
	        with(:body => "{\"recipient\":{\"id\":\"#{recipient}\"},\"message\":{\"attachment\":{\"type\":\"image\",\"payload\":{\"url\":\"https://s3.amazonaws.com/st-messenger/#{lib}/#{title}/#{title}#{i+1}.jpg\"}}}}",
	            :headers => {'Content-Type'=>'application/json'}).
	        to_return(:status => 200, :body => @success, :headers => {})
	    end
		end


		@stub_txt = lambda do |text|  
			success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
			stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
       with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"text\":\"#{text}\"}}",
            :headers => {'Content-Type'=>'application/json'}).
       to_return(:status => 200, :body => @success, :headers => {})			
		end

		@stub_arb = lambda do |text|  
			success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
			stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
       with(:body => text,
            :headers => {'Content-Type'=>'application/json'}).
       to_return(:status => 200, :body => @success, :headers => {})			
		end		

	end

	context '#assert_keys' do
		# should this fail gracefully?
		it 'fails gracefully when key assertion happens' do
			false
		end
	end

	# testing the button_story generation
	# => # => # => # => 
	# => # => # => # => 
	# => # => # => # => 
	context '#button_story' do
		before(:all) do
			@btn_name = 'poop'
		end

		before(:each) do
			@pb         = script_obj.postback_button('Tap here!', 'dumb_payload')
			@ubt  			= script_obj.url_button('Tap here!', 'http://example.com')
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
			

			User.create first_name:'Aubrey', last_name:'Wahl', child_name:'Lil Aubs', fb_id: @aubrey
		end

		before(:example, :story) do
			success = "{\"recipient_id\":\"10209571935726081\",\"message_id\":\"mid.1467836400908:1c1a5ec5710d550e83\"}"
			@stub_story.call(@aubrey, @lib,@title,@num_pages)
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
		

		# the use case here is if we do send(send_story{args...}), which doesn't have :text field
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
		# it 'expects certain arguments' do

		# end

		# it 'send correct story when ' do

		# end

		# it 'updates the last_story_read field' do

		# end


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


		# TODO: make this a webmock error
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

		it 'works when user has no teacher' do
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


	# Visual separation :P
	# => 
	# => 
	# =>
	# 
	context '#register_sequence' do
		before(:all) do
			@register_dumb_script = lambda do |name, return_str, script|
				script.sequence name do |recipient|
					return_str
				end				
			end
		end

		it 'registers correct number of sequences' do
      u = User.create(fb_id:@aubrey)		
      @register_dumb_script.call('seq1','a', script_obj)
      @register_dumb_script.call('seq1','b', script_obj)
      @register_dumb_script.call('seq1','c', script_obj)
      @register_dumb_script.call('seq2','d', script_obj)

			expect(script_obj.num_sequences).to eq(2)
			expect(script_obj.run_sequence(@aubrey,'seq1')).to eq('c')
			expect(script_obj.run_sequence(@aubrey,'seq2')).to eq('d')
		end

		it 'overwriting a sequence screws up :init' do
      u = User.create(fb_id:@aubrey)		
      @register_dumb_script.call('seq1','a', script_obj)
      @register_dumb_script.call('seq1','b', script_obj)
      @register_dumb_script.call('seq1','c', script_obj)
      @register_dumb_script.call('seq2','d', script_obj)
			expect(script_obj.run_sequence(@aubrey, :init)).to eq('a')
		end

		it 'errs when fallatious sequence, also DB is not updated' do
      u = User.create(fb_id: @aubrey)		
			old = u.state_table.last_sequence_seen
			
			# should change the last_sequence_seen
			expect{
	      @register_dumb_script.call('seq1','a', script_obj)
	      @register_dumb_script.call('seq2','b', script_obj)
				script_obj.run_sequence(@aubrey, :seq1)
			}.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from(nil).to 'seq1'

			# should raise error because fallatious
			expect{
				script_obj.run_sequence(@aubrey, :pee)
			}.to raise_error(NoMethodError)

			# should not have changed last_sequence_seen
			expect(User.where(fb_id:@aubrey).first.state_table.last_sequence_seen).to eq('seq1')
		end
	end




	# Visual separation :P
	# => 	
	# => 
	# =>
	# making sure that we play nicely with scripts
	# basically, we're running a larger part of stack
	context 'when #send, the DB should be updating, and ', script:true do
		before(:all) do

			@make_aubrey  = lambda do
				User.create phone:'3013328953', first_name:'Aubs', last_name:'Wahl', fb_id:@aubrey, child_name:'Lil Aubs'
			end

			@make_teacher  = lambda do
				Teacher.create email:'poop@pee.com', signature: 'Ms. McEsterWahl'
			end


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
					send recipient, text({text: txt})
					send recipient, button({name:'tap_here'}) 
				end
				sequence 'scratchstory' do |recipient|
					send recipient, story 
					img_1 = "https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg"
					send recipient, picture({url: img_1})
					send recipient, button({name: 'thanks'})
				end
				sequence 'yourwelcome' do |recipient|
					send recipient, text({text: "You're welcome :)"})
				end					
			
			end #=>END @cli.new_script 'day1' do

			@cli.new_script 'day2' do
				button_story({
					name: 		'tap_here',
					title: 		"You're next story's coming soon!",
					image_url:'https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg', 
					buttons: 	[postback_button('Tap here!', script_payload(:story))]
				})

				button_normal({
					name: 			 'thanks',
					window_text: "__TEACHER__: I’ll send another story tomorrow night :)",
					buttons: 			[postback_button('Thank you!', script_payload(:yourwelcome))]
				})			

				sequence 'differentfirst' do |recipient|
					txt = "__TEACHER__: Hi __PARENT__, here’s another story!"
					send recipient, text({text: txt})
					send recipient, button({name:'tap_here'}) 
				end
				sequence 'story' do |recipient|
					send recipient, story 
					img_1 = "https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg"
					send recipient, picture({url: img_1})
					send recipient, button({name: 'thanks'})
				end
				sequence 'yourwelcome' do |recipient|
					send recipient, text({text: "You're welcome :)"})
				end					
			
			end #=>END @cli.new_script 'day1' do			
			@s = @cli.scripts
		end #=>END before(:all) do



		context 'when updating last_sequence_seen it' do
			let (:u) {@make_aubrey.call}
			let (:t) {@make_teacher.call}

			before(:example) do
				t.add_user u

				# init sequence
				b1 = "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"generic\",\"elements\":[{\"title\":\"You're next story's coming soon!\",\"image_url\":\"https://s3.amazonaws.com/st-messenger/day1/tap_here.jpg\",\"subtitle\":\"\",\"buttons\":[{\"type\":\"postback\",\"title\":\"Tap here!\",\"payload\":\"day1_scratchstory\"}]}]}}}}"
				@stub_txt.call("Ms. McEsterWahl: Hi Aubs, here’s another story!")
				@stub_arb.call(b1)

				# scratchstory sequence
				b2 = "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"image\",\"payload\":{\"url\":\"https://s3.amazonaws.com/st-messenger/day1/scroll_up.jpg\"}}}}"
				b3 = "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"attachment\":{\"type\":\"template\",\"payload\":{\"template_type\":\"button\",\"text\":\"Ms. McEsterWahl: I’ll send another story tomorrow night :)\",\"buttons\":[{\"type\":\"postback\",\"title\":\"Thank you!\",\"payload\":\"day1_yourwelcome\"}]}}}}"			
				@stub_arb.call(b2)
				@stub_arb.call(b3)

			end

			it 'updates last sequence seen, nil->init->scratchstory' do
				pgs = Birdv::DSL::Curricula.get_version(0)[0][2]
				expect(pgs).to eq(2)	# only two pages of coon story
				expect(User.where(fb_id:@aubrey).first.state_table.story_number).to eq(0)
				expect(User.where(fb_id:@aubrey).first.curriculum_version).to eq(0)
				@stub_story.call(@aubrey, "day1","coon", pgs)
				#@stub_story.call(@aubrey, "day1","bird", 8)
				expect {
					@s['day1'].run_sequence(@aubrey, :init)
				}.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from(nil).to ('init')

				expect {
					@s['day1'].run_sequence(@aubrey, :scratchstory)
				}.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from('init').to ('scratchstory')			
			end

		end

		it 'sends the right story' do
			@make_aubrey.call
			@stub_story.call(@aubrey, 'day1', 'coon', 2)
			script = @s['day1']
			expect {
					script.send(@aubrey, script.story())
				}.not_to raise_error
		end

		it 'send(@aubrey, story()) updates story day' do
			@make_aubrey.call
			s1 = @s['day1']
			s2 = @s['day2']
			expect {
					@stub_story.call(@aubrey, 'day1', 'coon', 2)
					s1.send(@aubrey, s1.story())
					@stub_story.call(@aubrey, 'day1', 'cook', 11)
					s2.send(@aubrey, s2.story())
			}.to change{User.where(fb_id:@aubrey).first.state_table.story_number}.from(0).to(2)
		end

		it 'third story should work' do
			@make_aubrey.call
			s1 = @s['day1']
			s2 = @s['day2']
			expect {
					@stub_story.call(@aubrey, 'day1', 'coon', 2)
					s1.send(@aubrey, s1.story())
					@stub_story.call(@aubrey, 'day1', 'cook', 11)
					s2.send(@aubrey, s2.story())
					@stub_story.call(@aubrey, 'day1', 'scratch', 6)
					s2.send(@aubrey, s2.story())
			}.to change{User.where(fb_id:@aubrey).first.state_table.story_number}.from(0).to(3)

		end		

		it 'does not confuse last_sequence with last story_read' do
			@stub_txt.call("You're welcome :)")
			@make_aubrey.call
			s1 = @s['day1']
			s2 = @s['day2']
			expect {
					@stub_story.call(@aubrey, 'day1', 'coon', 2)
					s1.send(@aubrey, s1.story())
					@stub_story.call(@aubrey, 'day1', 'cook', 11)
					s2.send(@aubrey, s2.story())
					@stub_story.call(@aubrey, 'day1', 'scratch', 6)
					s2.send(@aubrey, s2.story())
					s2.run_sequence(@aubrey, 'yourwelcome')
			}.to change{User.where(fb_id:@aubrey).first.state_table.last_sequence_seen}.from(nil).to('yourwelcome')

			expect(User.where(fb_id:@aubrey).first.state_table.story_number).to eq(3)
		end
	end #=>END context 'when #send, the DB should be updated' do
end
