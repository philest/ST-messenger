source 'https://rubygems.org'


# this version of ruby seems to make jruby and cruby 
# play nicely. The jruby implementation we used is
# 9.0.5.0
def ruby_version_get
  if ENV['RUBY_VERSION']=='jruby'
    ['2.2.3',:engine=>'jruby',:engine_version=>'9.0.5.0']
  else
    ['2.2.3']
  end
end

params = ruby_version_get
ruby *params

if RUBY_ENGINE=='jruby'
  gem 'pg', '0.17.1', :platform => :jruby, :git => 'git://github.com/headius/jruby-pg.git', :branch => :master
  gem 'activerecord-jdbcpostgresql-adapter', 	'1.3.20'
else
  gem 'pg', 	'0.17.1'
end

gem 'sinatra'
gem 'dotenv', '~> 2.1', '>= 2.1.1'
gem 'airbrake'

# bot stuff
gem 'puma', 	'~>3.4.0'
gem 'twilio-ruby'
gem 'facebook-messenger'


# birdv stuff
gem 'httparty', '~>0.13.7'
gem 'rake', 	'11.1.2'
gem 'sequel', 	'~>4.35.0'
gem 'json'
gem 'redis', 	'3.3.0'
gem 'sidekiq', 	'~>4.1.2'
gem 'clockwork','~>2.0.0'
# gem 'concurrent-ruby', '~> 1.0', '>= 1.0.2'






group :test do
	gem 'rspec'
	gem 'webmock'
	gem 'capybara'
	gem 'rspec-sidekiq'
	gem 'factory_girl'
	gem "fakeredis", :require => "fakeredis/rspec"
	gem 'database_cleaner'
	gem 'rspec-mocks', '~> 3.4', '>= 3.4.1'
	gem 'timecop'
=begin
	gem 'capybara'
	gem 'selenium-webdriver'
	gem 'pry', "= 0.10.0"
	gem 'pry-nav'
	gem 'factory_girl'
=end	
end

