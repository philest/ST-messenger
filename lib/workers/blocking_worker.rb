class BlockingWorker
  include Sidekiq::Worker
  def perform(recipient, day_number)
  	i = 0
  	while(true)
			puts "#{i}..."
			sleep 1
		end
	end
end