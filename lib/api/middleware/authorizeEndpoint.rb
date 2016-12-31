require 'jwt'

class AuthorizeEndpoint
  include STATUS_CODES

  def initialize app
    @app = app
  end

  def call(env)
    begin

      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      # JWT decode magic
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      if payload['type'] != 'access'
        return [WRONG_ACCESS_TKN_TYPE, { 'Content-Type' => 'text/plain' }, ['Must be an access token (not refresh).']]
      end

      env[:user] = payload['user']

      # check if user doesn't exist anymore for some reason......
      if User.where(id: env[:user]['user_id']).first.nil?
        return [NO_EXISTING_USER, { 'Content-Type' => 'text/plain' }, ["User with id #{env[:user]['user_id']} doesn't exist"]]
      end

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
