$stdout.sync = true
$LOAD_PATH.unshift(File.dirname(__FILE__))

require_relative 'lib/app'
require 'bundler'
require 'sidekiq/web'
require 'facebook/messenger'
require_relative 'lib/bot'

run Rack::URLMap.new({
  #'/bot' => Facebook::Messenger::Server,
  '/' => Sinatra::Application, 
  '/sidekiq' => Sidekiq::Web
})


