require 'rake'
require 'sequel'
require 'dotenv'


ENV["RACK_ENV"] ||= "development"

pg_driver = RUBY_PLATFORM == 'java' ? 'jdbc:' : ''

case ENV["RACK_ENV"]
when "development", "test"
  require 'dotenv'
  Dotenv.load
  db_url    = "#{pg_driver}#{ENV['PG_URL_LOCAL']}"
when "production"
  require 'dotenv'
  Dotenv.load
  db_url    = "#{pg_driver}#{ENV['PG_URL']}"
end

DB = Sequel.connect(db_url)


# Rakefile

namespace :db do
  require "sequel"
  namespace :data do
    # dump everything to csv files
    task :dump, :dumpfile do |t, args|
      dumpfile = args[:dumpfile].to_s
    end

  end

  namespace :migrate do
    Sequel.extension :migration
    desc "Perform migration reset (full erase and migration up)"
    task :reset do
      Sequel::Migrator.run(DB, "db/migrations", :target => 0)
      Sequel::Migrator.run(DB, "db/migrations")
      puts "<= db:migrate:reset executed for #{ENV['RACK_ENV']}"
    end

    desc "Dump migration into schema"
    task :dump do
    	case ENV["RACK_ENV"]
    	when "test", "development"
    		db_url = ENV["DATABASE_URL_LOCAL"]
    	when "production" # will always be in production on heroku
    		db_url = ENV["DATABASE_URL"]
    	end
    	sh "sequel -d '#{db_url}' > './db/schema.rb'"
    	puts "<= schema located in db/schema.rb"
    end

    desc "Perform migration up/down to VERSION"
    task :to, :version do |t, args|
			version = args[:version].to_i
      # version = ENV['VERSION'].to_i
      raise "No VERSION was provided" if version.nil?
      Sequel::Migrator.run(DB, "db/migrations", :target => version)
      puts "<= db:migrate:to version=[#{version}] executed for #{ENV['RACK_ENV']}"
    end

    desc "Perform migration up to latest migration available"
    task :up do
      Sequel::Migrator.run(DB, "db/migrations")
      puts "<= db:migrate:up executed for #{ENV['RACK_ENV']}"
    end

    desc "Perform migration down (erase all data)"
    task :down do
      Sequel::Migrator.run(DB, "db/migrations", :target => 0)
      puts "<= db:migrate:down executed for #{ENV['RACK_ENV']}"
    end
  end
end
