class NotifyTeacherWorker
  include Sidekiq::Worker
  def perform(teacher_id)

  end
end