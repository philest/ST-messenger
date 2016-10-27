require_relative '../helpers/generate_phone_image'

class FlyerWorker
  include Sidekiq::Worker
  def perform(code, teacher, school)
    PhoneImage.create_image(code)
    FlyerImage.create_image(code, teacher, school)
  end
end