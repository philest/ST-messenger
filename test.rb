module Test
	module FB
		
		
		def print_thing
			puts "FB script"
		end
	end

	module SMS
		def print_thing
			puts "SMS script"
		end
	end

end


module Test

	class StoryTimeScript
		def initialize(platform)
			if platform == 'fb'
				self.extend(FB)
			else
				self.extend(SMS)
			end
		end
	end

end

s = Test::StoryTimeScript.new('sms')
s.print_thing