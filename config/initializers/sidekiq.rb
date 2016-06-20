# AFAIK sidekiq just picks this file up automatically 
require_relative 'bot/dsl'

# configure redis to use PG redis, or local if PG redis unavialible
# (you'd have to run redis-server on your own machine if not using 
# heroku redis!
redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/12'
Sidekiq.configure_server do |config|
    config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
    config.redis = { url: redis_url }
end
