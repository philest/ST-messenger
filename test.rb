
class Test
	def hi
		Hi.new.hello
	end
end

class Hi
	def hello
		puts "hello"
	end
end


Test.new.hi