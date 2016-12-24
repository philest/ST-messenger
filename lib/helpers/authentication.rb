require 'jwt' 

module Translate

  def translate(user, text)


  end
end



module STATUS_CODES
  SUCCESS               = 200
  CREATE_USER_SUCCESS   = 201
  MISSING_CREDENTIALS   = 400
  NO_MATCHING_SCHOOL    = 401
  NO_EXISTING_USER      = 402
  NO_VALID_ACCESS_TKN   = 403
  WRONG_PASSWORD        = 404
  WRONG_ACCESS_TKN_TYPE = 405
end

module Authentication

  def access_token(user_id)
    JWT.encode payload(user_id, 1.day, "access"), ENV['JWT_SECRET'], 'HS256'
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

class JWTAuth
  include STATUS_CODES

  def initialize app
    @app = app
  end

  def call(env)
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      # puts "auth = #{env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)}"

      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      puts "bearer = #{bearer}"
      puts "ENV = #{ENV['JWT_ISSUER']} #{ENV['JWT_SECRET']}"
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options
      puts "payload = #{payload.inspect}"

      if payload['type'] != 'access'
        return [WRONG_ACCESS_TKN_TYPE, { 'Content-Type' => 'text/plain' }, ['Must be an access token (not refresh).']]
      end

      # payload['user']['user_id']
      env[:user] = payload['user']

      # what should I return here? the full env object, or just the user?
      # depends on what we'll need.....
      @app.call(env)

    rescue JWT::DecodeError => e
      p e
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
    rescue JWT::ExpiredSignature
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [NO_VALID_ACCESS_TKN, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    end
  end
end



