class TestBot
  include Sidekiq::Worker

  sidekiq_options unique: :until_timeout, unique_job_expiration: 2.hours # 2 hours

  def perform(i, word)
    puts "performing job #{i}.... however it shall be done!"
  end
end