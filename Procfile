web: bundle exec puma -p $PORT
worker: bundle exec sidekiq -c 6 -r ./lib/clock.rb
clock: bundle exec clockwork ./lib/clock.rb
