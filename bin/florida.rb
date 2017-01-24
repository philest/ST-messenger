require_relative 'local'
require 'twilio-ruby'
require 'dotenv'
Dotenv.load

STORYTIME_NO  = "+12032023505"

STORYTIME_TEST_NO = "+12033496257"

client = Twilio::REST::Client.new ENV['TW_ACCOUNT_SID'], ENV['TW_AUTH_TOKEN']

# send them the messages
# delete them from the database simulataneously 


luciano = School.where(signature: "New Pines").first
users = User.where(school: luciano).all.select do |u|
    u.locale=='es' && u.platform.downcase == 'android'
end
puts users.map {|u| u.inspect }
puts users.count
users.each do |u|
    # send the text
    # do the twilio stuff here
    teacher_sig = u.teacher.signature
    locale = u.locale
    code = u.teacher.code

    class_code = code.split('|').first

    msg = "Hola #{u.first_name}! Es HHRC. Tus libros gratis de #{teacher_sig} están listos en Storytime.\n Consígalos en stbooks.org/app. Tu código de clase es #{class_code}"
    puts msg

    # client.account.messages.create(
    #   body: msg,
    #   to: u.phone,
    #   from: STORYTIME_NO
    # )
    puts "teacher=#{teacher_sig}, locale=#{locale}, class_code=#{class_code}, platform=#{u.platform}, phone=#{u.phone}"
end