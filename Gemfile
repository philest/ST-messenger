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

platform :jruby do
	# you do need both of these for postgres to work properly on jruby.
	# test on jruby 9.0.5.0
    gem 'pg_jruby'
    gem 'activerecord-jdbcpostgresql-adapter', 	'1.3.20'
end

platform :ruby do
  gem 'pg', 	'0.18.4'
end


gem 'dotenv', '~> 2.1', '>= 2.1.1'


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
=begin
	gem 'capybara'
	gem 'selenium-webdriver'
	gem 'pry', "= 0.10.0"
	gem 'pry-nav'
	gem 'factory_girl'
	gem 'timecop'
=end	
end

