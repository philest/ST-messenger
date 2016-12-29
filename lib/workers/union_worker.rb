class UnionWorker
  include Sidekiq::Worker
  def perform
    puts "striking.... striking.... striking...."
    sleep 0.5
  end
end