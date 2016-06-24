class BlockingWorker
  include Sidekiq::Worker
  def perform(num)
  	meth num
	end

	def meth(num)
		i = 0
  	while(true)
			puts "instance#{num} #{i}..."
			i+=1
			sleep 1
		end
	end
end