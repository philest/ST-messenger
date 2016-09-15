$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq/web'
require_relative 'config/initializers/redis'
require_relative 'config/initializers/airbrake'
require_relative 'lib/bot'
require 'sinatra'
require_relative 'lib/app' # the app which handles all text messaging stuff
require 'rack'
require_relative 'config/environment'
get_db_connection()


if RUBY_PLATFORM == 'jruby'
	require 'jdbc/postgres'
	# Jdbc::Postgres.load_driver
end

require_relative 'config/initializers/locale'

use Airbrake::Rack::Middleware

run Rack::URLMap.new({
  '/bot' => Facebook::Messenger::Server,
  '/' => SMS,
  '/sidekiq' => Sidekiq::Web
})




