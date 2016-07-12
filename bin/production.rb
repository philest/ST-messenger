require RUBY_PLATFORM == 'java' ? 'activerecord-jdbcpostgresql-adapter' : 'pg'
require 'sequel'
# use .env file for local development. no need for extra config files!
require 'dotenv'
Dotenv.load

puts "loading production db (storytime)..."
DB = Sequel.connect(ENV['DATABASE_URL_PRODUCTION'], :sslmode => 'require')

DB.timezone = :utc

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }