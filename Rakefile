require 'rake'
require 'sequel'
require_relative "config/environment"
# Rakefile

namespace :db do
  require "sequel"
  namespace :migrate do
    Sequel.extension :migration
    desc "Perform migration reset (full erase and migration up)"
    task :reset do
      Sequel::Migrator.run(DB, "db/migrations", :target => 0)
      Sequel::Migrator.run(DB, "db/migrations")
      puts "<= sq:migrate:reset executed"
    end

    desc "Dump migration into schema"
    task :dump do
    	case ENV["APP_ENV"]
    	when "test"
    		db_url = ENV["DATABASE_URL_LOCAL"]
    	when "development"
    		db_url = ENV["DATABASE_URL_REMOTE"]
    	when "production" # will always be in production on heroku
    		db_url = ENV["DATABASE_URL"]
    	end
    	sh "sequel -d '#{db_url}' > './db/test_schema'"
    	puts "<= schema located in db/test_schema"
    end

    desc "Perform migration up/down to VERSION"
    task :to, :version do |t, args|
			version = args[:version].to_i
      # version = ENV['VERSION'].to_i
      raise "No VERSION was provided" if version.nil?
      Sequel::Migrator.run(DB, "db/migrations", :target => version)
      puts "<= sq:migrate:to version=[#{version}] executed"
    end

    desc "Perform migration up to latest migration available"
    task :up do
      Sequel::Migrator.run(DB, "db/migrations")
      puts "<= sq:migrate:up executed"
    end

    desc "Perform migration down (erase all data)"
    task :down do
      Sequel::Migrator.run(DB, "db/migrations", :target => 0)
      puts "<= sq:migrate:down executed"
    end
  end
end
