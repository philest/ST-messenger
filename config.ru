$stdout.sync = true

require 'facebook/messenger'

require_relative 'lib/bot/bot'

run Rack::URLMap.new({
  '/bot' => Facebook::Messenger::Server
})


