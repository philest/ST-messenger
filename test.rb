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


module Fuck

  def ass_me
    puts @my_ass.to_s + "whatever, i don't care"
  end

end

class FuckingShit
  extend Fuck
  @my_ass = "is really huuuuuuuuge!"

end

FuckingShit.ass_me

module Test

  class StoryTimeScript
    def initialize(platform)
      if platform == 'fb'
        self.extend(FB)
      else
        self.extend(SMS)
      end
    end

    def perform(&block)
      yield

      if block
        puts block
        ret = instance_exec(&block)

        # yield
      else
        puts "ass"
      end
    end


  end

end

s = Test::StoryTimeScript.new('sms')

s.perform do 
  puts "I'm performing something, yes I am!"
end


s.print_thing