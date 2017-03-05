require_relative '../constants/statusCodes'


module AuthenticationHelpers

	include STATUS_CODES




	# return a JWT config payload
	def payload(user_id, exp, type, start_time = Time.now.to_i)
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






	# generate an access token
	def access_token(user_id, exp = 5.minutes, type = "access")
		JWT.encode payload(user_id, exp, type), ENV['JWT_SECRET'], 'HS256'
	end






	# generate a refresh token
	def create_refresh_token(user_id)
		JWT.encode payload(user_id, 6.months, "refresh"), ENV['JWT_SECRET'], 'HS256'
	end






	# JWT decoding with error handling
	def enhanced_jwt_decode(tkn, secret = ENV['JWT_SECRET'], validation = true, options = {})
		begin
			payload, header = JWT.decode tkn, secret, validation, options

		# https://philsturgeon.uk/http/2015/09/23/http-status-codes-are-not-enough/
		# we just need to optimize this a bit
		rescue JWT::ExpiredSignature
			return { err: true, code: TOKEN_EXPIRED,  title: 'The token has expired.' }
		rescue JWT::InvalidIssuerError
			return { err: true, code: TOKEN_INVALID,  title: 'The token does not have a valid issuer.' }
		rescue JWT::InvalidIatError
			return { err: true, code: TOKEN_INVALID,  title: 'The token does not have a valid "issued at" time.' }
		rescue JWT::DecodeError => e
			return { err: true, code: TOKEN_CORRUPT,  title: 'A token must be passed.' }
		end

		return payload, header
	end




	# returns true if enhanced_jwt_decode returned as error
	def decode_error(payload)
		if ( payload[:err] && payload[:code] && payload[:title])
			return true
		end
		return false
	end





	#########################################################
	#########################################################
	# TODO: move all of the following to own module somewhere
	
	# forgot password config
	def forgot_password_payload(user_id, start_time, life_length, random_code = "")
		config = {
			exp: start_time + life_length,
			iat: start_time,
			iss: ENV['JWT_ISSUER'],
			user: {
				user_id: user_id
			},
			type: 'reset password',
			life_length: life_length,
		}

		(random_code.empty? || random_code.nil?) ? config : config[:random_code] = random_code

		return config
	end



	# TODO: make this nicer
	def forgot_password_access_token(user_id, start_time, life_length)
		return JWT.encode forgot_password_payload(user_id, start_time, life_length), ENV['JWT_SECRET'], 'HS256'
	end



	def forgot_password_encode(user_id, start_time, life_length, random_code = "")
		return JWT.encode forgot_password_payload(user_id, start_time, life_length, random_code), ENV['JWT_SECRET'], 'HS256'
	end



	# returns the a hash with { user_id: some_id } if input
	# otherwise, returns an error hash with { code: some_error_code, title: some_error_message }
	def forgot_password_decode(tkn)

		options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }

		# decode tkn, error are caught in the the helper
		payload, header = enhanced_jwt_decode(tkn, ENV['JWT_SECRET'], true, options)

		# error case
		if payload['type'] != 'reset password'
			# return { err: true, code: TOKEN_INVALID,  title: 'Must pass a forgot password token' }]
			enhanced_payload  = payload
			enhanced_payload[:tokenTypeExpected] = 'reset password'
			return enhanced_payload
		end

		# this will return both good and bad outputs. It's user's responsibility to deal w it
		return payload

	end



end
