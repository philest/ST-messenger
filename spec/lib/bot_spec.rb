require 'spec_helper'
require 'bot'
# require_relative '../models/story'
require 'rack/test'


DAVID="10209967651611613"

describe "Bot", bot:true do
include Rack::Test::Methods
def app() Facebook::Messenger::Server end

	context "user-fb_id matching", :matching => true do

		# do the web mock
		before(:example) do
			WebMock.disable_net_connect!(allow_localhost:true, allow: [ENV['DATABASE_URL_LOCAL']])
			bad_id = "https://graph.facebook.com/v2.6/bad_id?access_token=#{ENV['FB_ACCESS_TKN']}&fields=first_name,last_name,profile_pic,locale,timezone,gender"
			david_req = "https://graph.facebook.com/v2.6/#{DAVID}?access_token=#{ENV['FB_ACCESS_TKN']}&fields=first_name,last_name,profile_pic,locale,timezone,gender"
			resp = "{\"first_name\":\"David\",\"last_name\":\"McPeek\",\"profile_pic\":\"https:\\/\\/scontent.xx.fbcdn.net\\/v\\/t1.0-1\\/p200x200\\/11888010_10207778015232072_3952470954126194921_n.jpg?oh=758fd621dcb4fc9e35ff639fbbe33c2e&oe=58309E0A\",\"locale\":\"en_US\",\"timezone\":-4,\"gender\":\"male\"}"

			

			error_resp = "{\"error\":{\"message\":\"(#803) Some of the aliases you requested do not exist: bad_id\",\"type\":\"OAuthException\",\"code\":803,\"fbtrace_id\":\"EfBCvlcrIvU\"}}"
			stub_request(:get, "https://graph.facebook.com/v2.6/bad_id?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD&fields=first_name,last_name,profile_pic,locale,timezone,gender").
         		to_return(:status => 200, :body => error_resp, :headers => {})

			stub_request(:get, david_req).
				to_return(:status => 200, :body => resp, :headers => {})

			stub_request(:get, bad_id).
         		with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
         		to_return(:status => 200, :body => "", :headers => {})      
    end

		it "creates a user with just a fb_id attribute on failure" do 
			bad_id = { "id" => "bad_id" }
			expect(User.count).to eq 0
			register_user(bad_id)
			expect(User.count).to eq 1
			user = User.first
			expect(user.fb_id).to eq "bad_id"

			expect(user.first_name).to be_nil
			expect(user.last_name).to be_nil
			expect(user.child_name).to be_nil
			expect(user.phone).to be_nil
		end

		it "matches fb_id to existing user with the same last name in the db" do
			init = User.create(:child_name => "Galen McPeek", :phone => "8186897323")
			fb_id = DAVID
			recipient = { "id" => fb_id }
			register_user(recipient)
			expect(User.count).to eq 1
			user = User.first
			expect(user.fb_id).to eq fb_id
			expect(user.first_name).to eq "David"
			expect(user.last_name).to eq "McPeek"
			expect(user.child_name).to eq "Galen McPeek"
			expect(user.phone).to eq "8186897323"
			expect(user.id).to eq init.id
		end

		# NOTE: 
		# V IMPORTANT
		# DON'T IGNORE THIS
		# !!!!!!!!!!!!!!!!!!!!!!!
		# if this test is failing, it may be because you forgot to do Timecop.return in 
		# another spec!
		it "picks the first user who matches a child when there are many of such users" do 
			candidate0 = User.create
			candidate1 = User.create(:child_name => "Ben McPeek")
			candidate2 = User.create(:child_name => "Emily McPeek")
			fb_id = DAVID
			recipient = { "id" => fb_id }
			register_user(recipient)
			#puts User.all.inspect
			expect(User.count).to eq 3
			
			expect(User.where(:id => candidate1.id).first.first_name).to eq "David"
			expect(User.where(:id => candidate1.id).first.last_name).to eq "McPeek"
		end

		it "retains teacher info for parents" do
			teacher = Teacher.create
			User.create(:child_name => "Fun Town USA")
			init = User.create(:child_name => "Galen McPeek", :phone => "8186897323")
			teacher.add_user(init)
			fb_id = DAVID
			recipient = { "id" => fb_id }
			register_user(recipient)
			user = User.where(:fb_id => fb_id).first
			expect(user.teacher.id).to eq teacher.id
			expect(user.phone).to eq init.phone
		end

		it "creates a new user when there is no matching user for the child in the database" do
			some_user = User.create(:child_name => "Phil Esterman", :phone => "phil_phone") 
			fb_id = DAVID
			recipient = { "id" => fb_id }
			register_user(recipient)
			expect(User.count).to eq 2
			user = User.where(:fb_id => fb_id)
			expect(user.count).to eq 1
			user = user.first
			expect(user.fb_id).to eq fb_id
			expect(user.first_name).to eq "David"
			expect(user.last_name).to eq "McPeek"
			expect(user.child_name).to be_nil
			expect(user.phone).to be_nil
			expect(user.id).to_not eq some_user.id
		end
	end

	describe '#fb_send_txt' do


	end

	describe "response-handling" do 
	
		describe "STOP" do
			before(:example) do
				@user = create(:user)
				@reply = get_reply("stop", @user)
	    	end

			it "unsubscribes them" do
				expect(@user.state_table.subscribed?).to be false
			end

			it "replies with confirmation" do 
				expect(@reply).to eq "Okay, you'll stop getting messages! If you want free books again just enter 'go.'"
			end 
		end

		describe "HELP" do 
			before(:example) do
				@user = create(:user)
				@reply = get_reply("help", @user)
	    	end

			it "replies correctly" do 
				expect(@reply).to eq "Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply 'stop'\n - For help, contact 561-212-5831"
			end 

		end 

		describe "WHO_IS_THIS" do 

			it "replies correctly to 'who is this'" do 
				@user = create(:user)
				@reply = get_reply("who is this", @user)
				expect(@reply).to eq "Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply 'stop'\n - For help, contact 561-212-5831"
			end 

			it "replies correctly to 'who's this'" do 
				@user = create(:user)
				@reply = get_reply("who's this", @user)
				expect(@reply).to eq "Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply 'stop'\n - For help, contact 561-212-5831"
			end

			it "replies correctly to 'who are you" do 
				@user = create(:user)
				@reply = get_reply("who are you", @user)
				expect(@reply).to eq "Hi, this is StoryTime! We help your teacher send free nightly stories.\n\n - To stop, reply 'stop'\n - For help, contact 561-212-5831"
			end 


		end 


		describe "UNKNOWN message" do 
			before(:example) do
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("This is a WICKED cool elit intervention!", @user)
	    	end

			it "replies correctly" do 
				expect(@reply).to eq "Hi __PARENT__! I'm away now but I'll see your message soon :)"
			end 

			context "when the last message was an unknown message" do
				before(:example) do

					@aubrey 	= '10209571935726081' # aubrey
				  @aub_db = User.create phone:'3013328953', first_name:'Aubs', last_name:'Wahl', fb_id:@aubrey, child_name:'Lil Aubs'

				  # expect(app).to receive(:get_reply).and_return("fakeeeee")


       stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
         with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"text\":\"I'll see your message by tonight! If you need more help just enter 'help'\"}}",
              :headers => {'Content-Type'=>'application/json'}).
         to_return(:status => 200, :body => "", :headers => {})

       stub_request(:post, "https://graph.facebook.com/v2.6/me/messages?access_token=EAAYOZCnHw2EUBAKs6JRf5KZBovzuHecxXBoH2e3R5rxEsWlAf9kPtcBPf22AmfWhxsObZAgn66eWzpZCsIZAcyX7RvCy7DSqJe8NVdfwzlFTZBxuZB0oZCw467jxR89FivW46DdLDMKjcYUt6IjM0TkIHMgYxi744y6ZCGLMbtNteUQZDZD").
         with(:body => "{\"recipient\":{\"id\":\"10209571935726081\"},\"message\":{\"text\":\"\"}}",
	         :headers => {'Content-Type'=>'application/json'}).
	         to_return(:status => 200, :body => "", :headers => {})     	
					# simulate an incoming FB message"
					# expect(User).to receive(:where).and_return([@aub_db])
			        @body = JSON.generate(
						        object: 'page',
						        entry: [
						          {
						            id: '1',
						            time: 145_776_419_824_6,
						            messaging: [
						              {
						                sender: {
						                  id: @aubrey
						                },
						                recipient: {
						                  id: '3'
						                },
						                timestamp: 145_776_419_762_7,
						                message: {
						                  mid: 'mid.1457764197618:41d102a3e1ae206a38',
						                  seq: 5,
						                  text: 'fake fake fake fake just my analysis'
						                }
						              }
						            ]
						          }
						        ]
						      )

				        @signature = OpenSSL::HMAC.hexdigest(
				          OpenSSL::Digest.new('sha1'),
				          Facebook::Messenger.config.app_secret,
				          @body
				        )
	      
					# post '/', @body, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{@signature}"
		    	end

		    	 it "gives the second unknown-reply" do
		    	 		post '/', @body, 'HTTP_X_HUB_SIGNATURE' => "sha1=#{@signature}"
		    	 end 

			end

		end

		describe "ROBOT message" do 
			it "replies correctly when asked if robot" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("Are you a robot?", @user)
				expect(@reply).to eq "Hi __PARENT__! StoryTime is an automated program that helps your teacher. If you need help just enter 'help.'"
			end 

			it "replies correctly when asked if automated" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("Is this automated?", @user)
				expect(@reply).to eq "Hi __PARENT__! StoryTime is an automated program that helps your teacher. If you need help just enter 'help.'"
			end 

			it "replies correctly when asked if person" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("Are you a person?", @user)
				expect(@reply).to eq "Hi __PARENT__! StoryTime is an automated program that helps your teacher. If you need help just enter 'help.'"
			end 


			it "replies correctly when asked if human" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("Are you a human?", @user)
				expect(@reply).to eq "Hi __PARENT__! StoryTime is an automated program that helps your teacher. If you need help just enter 'help.'"
			end 



		end

		describe "HAHA message" do 
			it "replies correctly" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("hahaha", @user)
				expect(@reply).to eq ":D"
			end 

			it "replies correctly" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("This is cool haha", @user)
				expect(@reply).to eq ":D"
			end 
		end 		 


		describe "THANK" do

			it "replies correctly to \'Thank you\'" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("Thank you", @user)
				expect(@reply).to eq "You're welcome :)"
			end 

			it "replies correctly to \'thanks\'" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("thanks", @user)
				expect(@reply).to eq "You're welcome :)"
			end

			it "replies correctly to \'THank YOU!!\'" do 
				@user = create(:user, first_name: "Ramon")
				@reply = get_reply("THank YOU!!", @user)
				expect(@reply).to eq "You're welcome :)"
			end 
		end  

		describe "LOVE" do
			before(:example) do
				@user = create(:user, first_name: "Ramon")
	    	end

			it "replies correctly to \'I love it\'" do 
				@reply = get_reply("I love it", @user)
				expect(@reply).to eq "^_^"
			end 

			it "replies correctly to \'They will love it\'" do 
				@reply = get_reply("They will love it", @user)
				expect(@reply).to eq "^_^"
			end

			it "replies correctly to \'They will like it\'" do
				@reply = get_reply("They will like it", @user)
				expect(@reply).to eq "^_^"
			end

			it "replies correctly to \'me gusta mucho\'" do
				@reply = get_reply("me gusta mucho", @user)
				expect(@reply).to eq "^_^"
			end


			it "replies correctly to \'they will enjoy it\'" do
				@reply = get_reply("they will enjoy it", @user)
				expect(@reply).to eq "^_^"
			end



			it "replies correctly to \'I do not love it\'"

		end


		describe "is_image?" do 
			context "when given a pure-ascii text" do 
	 
				it "say no" do
					@attachments = nil 
					expect(is_image?(@attachments)).to be false
				end 
			end 

			context "when given an image" do 
				before(:example) do 
					@attachments = [
								      {
								        "type":"image",
								        "payload":{
								          "url":"IMAGE_URL"
								        }
								      }
								    ]
				end 
				
				it "says yes" do 
					expect(is_image?(@attachments)).to be true
				end



			end


		end 
	end






end