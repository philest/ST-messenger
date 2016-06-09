source 'https://rubygems.org'

# this version of ruby seems to make jruby and cruby 
# play nicely. The jruby implementation we used is
# 9.0.5.0
ruby '2.2.3'

platform :jruby do
	# you do need both of these for postgres to work properly on jruby.
	# test on jruby 9.0.5.0
    gem 'pg_jruby', 							'0.17.1-java'
    gem 'activerecord-jdbcpostgresql-adapter', 	'1.3.20'
end

platform :ruby do
  gem 'pg', 	'0.18.4'
end

gem 'puma', 	'~>3.4.0'
gem 'httparty', '~>0.13.7'
gem 'rake', 	'11.1.2'
gem 'sequel', 	'~>4.35.0'

gem 'redis', 	'3.3.0'
gem 'sidekiq', 	'~>4.1.2'
gem 'clockwork','~>2.0.0'


group :test do
	gem 'rspec'
=begin
	gem 'capybara'
	gem 'selenium-webdriver'
	gem 'database_cleaner'
	gem 'pry', "= 0.10.0"
	gem 'pry-nav'
	gem 'timecop'
	gem 'factory_girl'
	gem 'fakeredis', :require => 'fakeredis/rspec'
=end	
end