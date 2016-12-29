require 'sequel'
require 'dotenv'
Dotenv.load

require 'active_support/time'

puts "loading local db (test)..."

# story_count
$story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../lib/sequence_scripts/*")
                .inject(0) do |sum, n|
                  if /\d+\.rb/.match n
                    sum + 1
                  else  
                    sum
                  end
                end

$sms_story_count = Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../lib/sms_sequence_scripts/*")
                .inject(0) do |sum, n|
                  if /\d+\.rb/.match n
                    sum + 1
                  else  
                    sum
                  end
                end

pg_driver = RUBY_PLATFORM == 'java' ? 'jdbc:' : ''

db_url = "#{pg_driver}#{ENV['PG_URL_LOCAL']}"

DB = Sequel.connect(db_url)

DB.timezone = :utc

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }