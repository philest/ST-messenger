require 'rake'
require 'sequel'
require 'dotenv'
Dotenv.load

ENV["RACK_ENV"] ||= "development"

case ENV["RACK_ENV"]
when "local", "test", "development"
  DB = Sequel.connect(ENV['DATABASE_URL_LOCAL'])
when "production"
  DB = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
end

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
      # Sequel::Migrator.run(DB, "db/migrations")
      puts "<= db:migrate:reset executed for #{ENV['RACK_ENV']}"
    end

    desc "Dump migration into schema"
    task :dump do
    	case ENV["RACK_ENV"]
    	when "test"
    		db_url = ENV["DATABASE_URL_LOCAL"]
    	when "development"
    		db_url = ENV["DATABASE_URL_REMOTE"]
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
