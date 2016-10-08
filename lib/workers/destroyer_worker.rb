class DestroyerWorker
  include Sidekiq::Worker
  def perform(user_id)
    User.where(id: user_id).first.destroy
  end
end