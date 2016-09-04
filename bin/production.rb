require 'sequel'
require 'dotenv'
Dotenv.load

require 'active_support/time'

puts "loading production db (storytime)..."

pg_driver = RUBY_PLATFORM == 'java' ? 'jdbc:' : ''

db_url = "#{pg_driver}#{ENV['PG_URL']}"

DB = Sequel.connect(db_url)

DB.timezone = :utc

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }