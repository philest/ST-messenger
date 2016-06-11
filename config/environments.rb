require 'sequel'
# use .env file for local development. no need for extra config files!
require 'dotenv'
Dotenv.load
#The environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path

if ENV["APP_ENV"] == "development" || ENV["APP_ENV"] == "test"
	puts "loading local db..."
	DB = Sequel.connect(ENV['DATABASE_URL_LOCAL'])

else # production!
	puts "loading production db..."
	DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
end