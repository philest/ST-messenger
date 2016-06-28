$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))



require 'bundler'
require 'sidekiq'
require 'sidekiq/web'
require_relative 'lib/bot'
require 'sinatra'

require 'rack'
require 'airbrake'
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



run Rack::URLMap.new({
  '/' => Facebook::Messenger::Server,
  '/sidekiq' => Sidekiq::Web
})


