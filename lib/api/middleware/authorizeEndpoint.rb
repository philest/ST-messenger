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


      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options
      
      if payload['type'] != 'access'
        return 404, jsonError(TOKEN_WRONG, 'Must give access token (not refresh, or otherwise)')
      end



      # check if user doesn't exist anymore for some reason.
      env[:user] = payload['user']

      if User.where(id: env[:user]['user_id']).first.nil?
        return 404, jsonError(USER_NOT_EXIST, 'The user you are looking for does not exist')
      end


    # error handling, following a philosophy inspired by this article:
    # https://philsturgeon.uk/http/2015/09/23/http-status-codes-are-not-enough/
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

    @app.call(env)

  end
end
