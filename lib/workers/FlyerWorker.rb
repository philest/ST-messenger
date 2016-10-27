require_relative '../helpers/generate_phone_image'

class FlyerWorker
  include Sidekiq::Worker
  def perform(teacher_id, school_id)
    teacher = Teacher.where(id: teacher_id).first
    school  = School.where(id: school_id).first

    PhoneImage.create_image(teacher, school)
    FlyerImage.create_image(teacher, school)
  end
end