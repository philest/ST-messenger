#require RUBY_PLATFORM == 'java' ? 'activerecord-jdbcpostgresql-adapter' : 'pg'
#require 'activerecord-jdbcpostgresql-adapter'
#require 'jdbc/postgres'
require 'sequel'
# use .env file for local development. no need for extra config files!
require 'dotenv'
Dotenv.load

puts "loading production db (storytime)..."
str = 'jdbc:postgresql://ec2-50-17-255-136.compute-1.amazonaws.com/dbucanki0t9she?user=tqagrsafzmxzgm&password=iqk1V54QPOjH5nJul_ee3hSEsb&sslmode=require'
DB = Sequel.connect(str, :sslmode => 'require')

DB.timezone = :utc

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }
