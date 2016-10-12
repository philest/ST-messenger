source 'https://rubygems.org'


# this version of ruby seems to make jruby and cruby 
# play nicely. The jruby implementation we used is
# 9.0.5.0
# def ruby_version_get
#   if ENV['RUBY_VERSION']=='jruby'
#     ['2.2.3',:engine=>'jruby',:engine_version=>'9.0.5.0']
#   else
#     ['2.2.3']
#   end
# end

# params = ruby_version_get
ruby '2.3.1'

# if RUBY_ENGINE=='jruby'
#   	# gem 'activerecord-jdbcpostgresql-adapter', 	'1.3.20'
#   	gem 'jdbc-postgres', '~> 9.4', '>= 9.4.1206'
# else
#   gem 'pg', 	'0.17.1'

# end

gem 'gruff'

gem 'pg'


gem 'airbrake'

# bot stuff
# gem 'puma', 	'~>3.4.0'
gem 'puma'
gem 'facebook-messenger'
gem 'sinatra'

# gem 'i18n', '~> 0.7.0'
gem 'i18n'

# birdv stuff
gem 'httparty'
gem 'rake'
gem 'sequel'
gem 'json'
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'clockwork'
gem 'pony'
gem 'twilio-ruby'

gem 'dotenv'

group :production do
	gem 'newrelic_rpm'
end



group :test do
	gem 'fuubar'
	gem 'email_spec'
	gem 'pry'
	gem 'pry-nav'
	gem 'rack-test'
	gem 'rspec'
	gem 'webmock'
	gem 'capybara'
	gem 'rspec-sidekiq'
	gem 'factory_girl'
	gem "fakeredis", :require => "fakeredis/rspec"
	gem 'database_cleaner'
	gem 'rspec-mocks'
	gem 'timecop'
=begin
	gem 'capybara'
	gem 'selenium-webdriver'
	gem 'pry', "= 0.10.0"
	gem 'pry-nav'
	gem 'factory_girl'
=end	
end

