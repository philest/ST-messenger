require_relative "../helpers/fb"

class BotWorker 
  include Sidekiq::Worker
  include Facebook::Messenger::Helpers
  sidekiq_options :retry => 3
  # sidekiq_retry_in do |count|
  #   10
  # end
	def perform(recipient, script_name, sequence, day_increment=nil)
			# puts "script name: #{script_name}, sequence name: #{sequence}"
	  	# load script
	  	s = Birdv::DSL::StoryTimeScript.scripts[script_name]
	  	puts "about to send #{script_name}"
	  	if not s.nil?
	  		puts "script exists"
			# open DB connection, log the button press
			u = User.where(:fb_id=>recipient).first

			# enroll user if they are not in the db
			if u.nil?
				register_user({'id'=>recipient})
				u = User.where(:fb_id=>recipient).first
			end

			# check if user has already pressed that button...
			history = ButtonPressLog.where(:user_id=>u.id, :day_number=>s.script_day, :sequence_name=>sequence).first
			
			if history.nil? or Time.now.utc - history.created_at.utc > 2.minutes # if indeed they haven't pressed this button before or it's been at least 2 minutes
				puts "we haven't pressed that button before"
				b = ButtonPressLog.new(:day_number=>s.script_day, :sequence_name=>sequence)
				u.add_button_press_log(b)
				
				# run the script in question
				s.run_sequence(recipient, sequence.to_sym)
				
				# increment the user's reading day if necessary
				if s.script_day >= u.story_number
					u.update(:story_number => s.script_day+1)
				end
			
			else 
				puts "we HAVE pressed this button before, don't send twice"
				fb_send_txt({'id' => recipient}, "Excited for more stories? We'll send some more your way tomorrow night!")
			end

		end
	end

	# TODO, add completed to a DONE pile. some day sequel -m db/migrations postgres://host/database
end
