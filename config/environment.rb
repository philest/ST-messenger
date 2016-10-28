require 'sequel'

def get_db_connection(max_connections=6)
  #The environment variable PG_URL should be in the following format:
  # => postgresql://{host}:{port}/{database}?user={user}&password={password}
  ENV["RACK_ENV"] ||= "development"
  puts "loading #{ENV['RACK_ENV']} db..."
  pg_driver = RUBY_PLATFORM == 'java' ? 'jdbc:' : ''

  case ENV["RACK_ENV"]
  when "development", "test"
    require 'dotenv'
    puts '!!! loading up local environment vars...'
    Dotenv.load
    db_url    = "#{pg_driver}#{ENV['PG_URL_LOCAL']}"
    puts "db_url = #{db_url}"
    db        = Sequel.connect(db_url)
  when "production"
    db_url    = "#{pg_driver}#{ENV['PG_URL']}"
    puts "db_url = #{db_url}"
    db        = Sequel.connect(db_url, :max_connections => (max_connections))
  end

  db.timezone = :utc

  models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
  Dir[models_dir].each {|file| require_relative file }

  return db
end







