require RUBY_PLATFORM == 'java' ? 'activerecord-jdbcpostgresql-adapter' : 'pg'
require 'sequel'
require './ENV_LOCAL'
DB = Sequel.connect(DATABASE_URL)
require_relative '../models/user.rb'
require_relative '../models/story.rb'

