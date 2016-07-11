class TestBot
  include Sidekiq::Worker
  def perform
    puts "performing a job.... however it shall be done!"
  end
end