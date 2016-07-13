require 'sequel'

#The environment variable PG_URL should be in the following format:
# => postgresql://{host}:{port}/{database}?user={user}&password={password}
ENV["RACK_ENV"] ||= "development"

case ENV["RACK_ENV"]
when "development", "test"
  require 'dotenv'
  Dotenv.load
  puts "loading local db..."
  DB = Sequel.connect(ENV['DATABASE_URL_LOCAL'])
#when "development"
# puts "loading development db (quailtime)..."
# DB = Sequel.connect(ENV['DATABASE_URL_DEVELOPMENT'])
when "production"
  puts "loading production db (storytime)..."
    # heroku says that we generally wanna have same pool size as threads 
  # https://devcenter.heroku.com/articles/concurrency-and-database-connections#threaded-servers
  # but I'm gonna do 6 because I expect each of the web, worker, and clock will be using
  # seperate connections... TODO: not sure if this is true.
  DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require', :max_connections => (6))
else
  puts "please specify an RACK_ENV in environment.rb, defaulting to local..."
  DB = Sequel.connect(ENV['DATABASE_URL_LOCAL'])
end

DB.timezone = :utc

# require all models
# Dir[File.dirname(__FILE__) + "/*.rb"].each {|file| require_relative file if not file =~ /#{__FILE__}/ }

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }


