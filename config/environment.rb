require RUBY_PLATFORM == 'java' ? 'activerecord-jdbcpostgresql-adapter' : 'pg'
require 'sequel'
# use .env file for local development. no need for extra config files!
require 'dotenv'
Dotenv.load
#The environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path



case ENV["APP_ENV"]
when "test"
	puts "loading local db..."
	DB = Sequel.connect(ENV['DATABASE_URL_LOCAL'])
when "development"
	puts "loading development db (quailtime)..."
	DB = Sequel.connect(ENV['DATABASE_URL_QUAILTIME'])
when "production"
	puts "loading production db (storytime)..."
	DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
else
	puts "please specify an APP_ENV in environment.rb, defaulting to production..."
	DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
end

DB.timezone = :utc

# require all models
# Dir[File.dirname(__FILE__) + "/*.rb"].each {|file| require_relative file if not file =~ /#{__FILE__}/ }

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }

# require_relative '../models/classroom.rb'
# require_relative '../models/district.rb'
# require_relative '../models/school.rb'
# require_relative '../models/school_sessions.rb'
# require_relative '../models/story.rb'
# require_relative '../models/teacher.rb'
# require_relative '../models/user.rb'
