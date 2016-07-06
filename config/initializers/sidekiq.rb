# AFAIK sidekiq just picks this file up automatically 
puts "haaaaaaaay from sidekiq"
# configure redis to use PG redis, or local if PG redis unavialible
# (you'd have to run redis-server on your own machine if not using 
# heroku redis!
redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/12'

# suggested to track errors on sidekiq
Sidekiq.configure_server do |config| config.error_handlers << Proc.new { |ex,ctx_hash| Airbrake.notify_or_ignore(ex, ctx_hash) } end