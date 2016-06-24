web: bundle exec puma 
worker: bundle exec sidekiq  -c 6 -r ./lib/workers.rb
clock: bundle exec clockwork ./lib/clock.rb
