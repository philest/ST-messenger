class StoryTimeScriptWorker
  include Sidekiq::Worker

  def perform(recipient, script_name, sequence)
		Birdv::DSL::StoryTimeScript.scripts[script_name].run_sequence(recipient, sequence.to_sym)
	end

	# TODO, add completed to a DONE pile. some day
end
