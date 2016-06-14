require RUBY_PLATFORM == 'java' ? 'activerecord-jdbcpostgresql-adapter' : 'pg'
require 'sequel'
# use .env file for local development. no need for extra config files!
require 'dotenv'
Dotenv.load
#The environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path



case ENV["APP_ENV"]
when "development", "test"
	puts "loading local db..."
	DB = Sequel.connect(ENV['DATABASE_URL_LOCAL'])
when "production"
	puts "loading production db..."
	DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
else
	puts "please specify an APP_ENV in environment.rb, defaulting to production..."
	DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
end

require_relative '../models/user.rb'
require_relative '../models/story.rb'