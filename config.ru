$stdout.sync = true


require 'bundler'
require './lib/app/app.rb'
require 'sidekiq/web'


require 'facebook/messenger'
require_relative 'lib/bot/bot'

run Rack::URLMap.new({
  '/bot' => Facebook::Messenger::Server,
  '/' => Sinatra::Application, 
  '/sidekiq' => Sidekiq::Web
})


