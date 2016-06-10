require 'sequel'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
require 'pg' if RUBY_PLATFORM != 'java'

class Test < Sequel::Model
	set_schema do
		primary_key :id
		String :name
	end
end