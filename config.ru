$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))



require 'bundler'
require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq/web'
require_relative 'lib/bot'
require 'sinatra'
require_relative 'lib/app' # the app which handles all text messaging stuff

require 'rack'
require 'airbrake'
# require 'airbrake/sidekiq'
require 'airbrake/sidekiq/error_handler'

configure :production do
	require 'newrelic_rpm'

	Airbrake.configure do |config|
	  config.project_id = ENV['AIRBRAKE_PROJECT_ID']
	  config.project_key = ENV['AIRBRAKE_API_KEY']
	  config.environment = ENV['RACK_ENV'] || "development"
	end
	use Airbrake::Rack::Middleware
end

if RUBY_PLATFORM == 'jruby'
	require 'jdbc/postgres'
	# Jdbc::Postgres.load_driver
end

require_relative 'config/initializers/locale'


run Rack::URLMap.new({
  '/bot' => Facebook::Messenger::Server,
  '/' => SMS,
  '/sidekiq' => Sidekiq::Web
})


