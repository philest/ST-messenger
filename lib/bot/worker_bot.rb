class StoryTimeScriptWorker
  include Sidekiq::Worker

  def perform(recipient, day_number, sequence)
		Birdv::DSL::StoryTimeScript.scripts['day_#{day_number}'].run_sequence(recipient, sequence.to_sym)
	end

	# TODO, add completed to a DONE pile. some day
end
