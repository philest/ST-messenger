module AuthenticationHelpers




  def access_token(user_id)
    JWT.encode payload(user_id, 5.minutes, "access"), ENV['JWT_SECRET'], 'HS256'
  end




  def refresh_token(user_id)
    JWT.encode payload(user_id, 6.months, "refresh"), ENV['JWT_SECRET'], 'HS256'
  end





  def forgot_password_encode(user_id, start_time, life_length, random_code = "")

    # TODO: check type of start_time
    type = "reset password"

    config = {
      exp: start_time + life_length,
      iat: start_time,
      iss: ENV['JWT_ISSUER'],
      user: {
        user_id: user_id
      },
      type: type,
      random_code: random_code,
      start_time: start_time,
      lift_length: life_length,
    }

    return JWT.encode config, ENV['JWT_SECRET'], 'HS256'
  end





  # returns the a hash with { user_id: some_id } if input
  # otherwise, returns an error hash with { code: some_error_code, msg: some_error_message }
  def forgot_password_decode(tkn)

    begin

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }

      # decode tkn
      payload, header = JWT.decode tkn, ENV['JWT_SECRET'], true, options


      if payload['type'] != 'reset password'
        return { code: TOKEN_INVALID,  msg: 'Must pass a forgot password token'}
      end


    # https://philsturgeon.uk/http/2015/09/23/http-status-codes-are-not-enough/
    # we just need to optimize this a bit
    rescue JWT::DecodeError => e
      return { code: TOKEN_CORRUPT,  msg: 'A token must be passed.' }
    rescue JWT::ExpiredSignature
      return { code: TOKEN_EXPIRED,  msg: 'The token has expired.' }
    rescue JWT::InvalidIssuerError
      return { code: TOKEN_INVALID,  msg: 'The token does not have a valid issuer.' }
    rescue JWT::InvalidIatError
      return { code: TOKEN_INVALID,  msg: 'The token does not have a valid "issued at" time.' }
    end

    return { user_id: payload['user']['user_id'] }


  end





  def payload(user_id, exp, type)
    start_time = Time.now.to_i
    config = {
      exp: start_time + exp.to_i,
      iat: start_time,
      iss: ENV['JWT_ISSUER'],
      user: {
        user_id: user_id
      },
      type: type
    }

    return config
  end

end
