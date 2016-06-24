$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'config/environment'

require 'bundler'
require 'sidekiq'
require 'sidekiq/web'
require 'facebook/messenger'
require_relative 'lib/bot'
require_relative 'lib/app'

run Rack::URLMap.new({
  #'/bot' => Facebook::Messenger::Server,
  '/' => Sinatra::Application, 
  '/sidekiq' => Sidekiq::Web
})


