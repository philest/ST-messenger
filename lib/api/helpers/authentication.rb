module AuthenticationHelpers

  def access_token(user_id)
    puts "HHHHHHHHHIIIIIIIIIIIIIIIIIIIII<<<<<<<<<<<<<<<<<<"
    JWT.encode payload(user_id, 3.seconds, "access"), ENV['JWT_SECRET'], 'HS256'
  end

  def refresh_token(user_id)
    JWT.encode payload(user_id, 6.months, "refresh"), ENV['JWT_SECRET'], 'HS256'
  end

  def payload(user_id, exp, type)
    {
      exp: Time.now.to_i + exp.to_i,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      user: {
        user_id: user_id
      },
      type: type
    }
  end

end
