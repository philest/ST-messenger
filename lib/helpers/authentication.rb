require 'jwt' 

module STATUS_CODES
  CREATE_USER_SUCCESS   = 201
  NO_MATCHING_SCHOOL    = 401
  NO_EXISTING_USER      = 402
  NO_VALID_ACCESS_TKN   = 403
  WRONG_PASSWORD        = 404
end

module Authentication

  def access_token(user_id)
    JWT.encode payload(user_id, 1.day), ENV['JWT_SECRET'], 'HS256'
  end

  def refresh_token(user_id)
    JWT.encode payload(user_id, 6.months), ENV['JWT_SECRET'], 'HS256'
  end

  def payload(user_id, exp)
    {
      exp: exp,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      user: {
        user_id: user_id
      }
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
      puts "auth = #{env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)}"
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      # payload['user']['user_id']
      env[:user] = payload['user']

      # what should I return here? the full env object, or just the user?
      # depends on what we'll need.....
      @app.call(env)

    rescue JWT::DecodeError
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



