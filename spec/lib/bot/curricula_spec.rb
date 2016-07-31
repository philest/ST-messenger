require 'spec_helper'
require 'bot/curricula'

describe Birdv::DSL::Curricula do

	before(:all) do
		  #load curriculae
      dir = "#{File.expand_path(File.dirname(__FILE__))}/unit_test_curricula/"
      @c 	= Birdv::DSL::Curricula.load(dir, absolute=true) 
			puts @c
	end
 	
 	it 'strips whitespace' do
 		expect(@c['has_whitespace'][0][1] =~ /\s/).to be nil
 	end


 	it 'accepts integer version names, converts into int' do
 		expect(@c[0]).not_to be nil
 	end

 	it 'accepts string version names' do
 		expect(@c['has_whitespace']).not_to be nil
 	end 
	
end