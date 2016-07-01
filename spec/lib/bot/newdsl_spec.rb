require 'spec_helper'
require 'bot/newdsl'

describe Birdv::DSL::StoryTimeScript do

	let (:script_obj) {Birdv::DSL::StoryTimeScript.new('examp') do end}
	
	before(:each) do

		@pb         = script_obj.postback_button('Tap here!', 'dumb_payload')
		@ubt  			= script_obj.url_button('Tap here!', 'http://example.com')

	end


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
	end


	context '#button_normal' do
		it 'hash has required properties' do

		end

		it 'registers newly made button' do

		end
	end



	context '#button' do
		it 'returns json when argument is string' do

		end

		it 'returns json when argument is hash' do

		end
	end

	context '#text' do
		it 'hash has required propterties' do

		end
	end

	context '#picture' do
		it 'hash has required propterties' do

		end
	end


end