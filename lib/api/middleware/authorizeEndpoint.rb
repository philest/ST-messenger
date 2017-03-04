require 'jwt'
require_relative '../helpers/json_macros'
class AuthorizeEndpoint
  include STATUS_CODES
  include JSONMacros

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

    # https://philsturgeon.uk/http/2015/09/23/http-status-codes-are-not-enough/
    # we just need to optimize this a bit
    rescue JWT::ExpiredSignature
      return 404, jsonError(TOKEN_EXPIRED, 'The token has expired.')
    rescue JWT::InvalidIssuerError
      return 404, jsonError(TOKEN_INVALID, 'The token does not have a valid issuer.')
    rescue JWT::InvalidIatError
      return 404, jsonError(TOKEN_INVALID, 'The token does not have a valid "issued at" time.')
    rescue JWT::DecodeError => e
      puts e
      return 404, jsonError(TOKEN_CORRUPT, 'A token must be passed.')
    end
  end
end
