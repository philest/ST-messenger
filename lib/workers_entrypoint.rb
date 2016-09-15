require 'sidekiq'
require 'active_support/time'
require 'rack'

require 'airbrake'
require 'airbrake/sidekiq/error_handler'
require_relative '../config/environment'
get_db_connection()
require_relative '../config/initializers/redis'


Airbrake.configure do |config|
    config.project_id = ENV['AIRBRAKE_PROJECT_ID']
    config.project_key = ENV['AIRBRAKE_API_KEY']
    # config.ignore_environments = %w(development test)
    config.environment = ENV['RACK_ENV'] || "development"
end

require_relative 'workers'