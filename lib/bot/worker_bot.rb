class StoryTimeScriptWorker
  include Sidekiq::Worker

  def perform(recipient, script_name, sequence, day_increment=nil)
		
  	# load script
  	s = scripts[script_name]

		# open DB connection, log the button press
		u = User.where(:fb_id=>recipient).first
		b = ButtonPressLog.new(:day_number=>s.script_day, :sequence_name=>sequence)
		u.add_button_press_log(b)
		
		# run the script in question
		Birdv::DSL::StoryTimeScript.scripts[script_name].run_sequence(recipient, sequence.to_sym)
		
		# increment the user's reading day if necessary
		if day_increment != nil
			u.story_number += 1
			u.save
		end
	end

	# TODO, add completed to a DONE pile. some day sequel -m db/migrations postgres://host/database
end
