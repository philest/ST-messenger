require_relative '../helpers/fb'

class BotWorker 
  include Sidekiq::Worker
  include Facebook::Messenger::Helpers
  sidekiq_options :retry => 1

	def perform(recipient, script_name, sequence, day_increment=nil)

	  	# load script
	  	s = Birdv::DSL::ScriptClient.scripts[script_name]

	  	Sidekiq.logger.warn(s.nil? ? "couldn't find script #{script_name}" : "about to send #{script_name}" )

	  	if not s.nil?
			# enroll user if they are not in the db
			if User.where(fb_id:recipient).first.nil?
				register_user({'id'=>recipient})
			end
			
			# open DB connection to user
			u = User.where(fb_id:recipient).first		

			# check if user has already pressed that button...
			history = ButtonPressLog.where(:user_id=>u.id, :day_number=>s.script_day, :sequence_name=>sequence).first
			Sidekiq.logger.warn "history = #{history.to_s}"

			# log the button anyway...
			b = ButtonPressLog.new(:day_number=>s.script_day, :sequence_name=>sequence)
			u.add_button_press_log(b)

			protected_ids = %w(1084495154927802 1042751019139427 1625783961083197 10209967651611613)
			puts "id = #{recipient}"
			puts "included? #{protected_ids.include?(recipient)}"

			# ...but if they didn't already press the button, send sequence
			if history.nil? \
				|| history.sequence_name == 'intro' \
				|| history.sequence_name == 'teachersend' \
				|| protected_ids.include?(recipient)

				puts "we haven't seen this button before..."
				# TODO: run this in a worker
				# run the script
				s.run_sequence(recipient, sequence.to_sym)
				
				# increment the user's reading day if necessary
				if s.script_day >= u.story_number
					u.update(:story_number => s.script_day+1)
				end
			else
				puts "we've seen this button before..."

			end

			# TODO: do we want an ELSE behavior?
		end
	end
end
