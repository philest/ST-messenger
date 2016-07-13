require 'spec_helper'
require 'bot/dsl'

# when you don't pass in a hash

# warn when you do the wrong thing, e.g. button({text:'button_name_here'})

# fail gracefully when there's a bad payload?

# when fail, just let facebook know that a probs so it doesn't try again later?

describe 'CorrectStoryTimeScripts' do
	before(:all) do
		@num = 0
		@aubrey 	= '10209571935726081'

		@make_aubrey  = lambda do
			User.create phone:'3013328953', first_name:'Aubs', last_name:'Wahl', fb_id:@aubrey, child_name:'Lil Aubs'
		end

		@make_teacher  = lambda do
			Teacher.create email:'poop@pee.com', signature: 'Ms. McEsterWahl'
		end

		@make_aubrey.call
		@make_teacher.call



		# load everytin' uppppp
		expect {
			Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../../lib/sequence_scripts/*")
				.each {|f| require_relative f; @num+=1 }
		}.not_to raise_error	

		@s = Birdv::DSL::ScriptClient.scripts
	end

	it 'loads all scripts in directory' do
		expect(Birdv::DSL::ScriptClient.scripts.size).to eq @num
	end

	it "runs each sequence in scripts without quarell" do

		@s.values.each do |script|
			sqncs =  script.sequences
			sqncs.keys.each do |sqnce_name|
				expect{
					script.run_sequence(@aubrey, sqnce_name)
				}.not_to raise_error
			end
		end
	end






end