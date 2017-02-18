require 'sequel'
require 'dotenv'
require 'bcrypt'
include BCrypt
Dotenv.load

require 'active_support/time'

puts "loading production db (storytime)..."
require 'pg'
puts "is threadsafe = #{PG::Connection.isthreadsafe}"

db_url = "#{ENV['DATABASE_URL']}"

DB = Sequel.connect(db_url)

DB.timezone = :utc

models_dir = File.expand_path("../models/*.rb", File.dirname(__FILE__))
Dir[models_dir].each {|file| require_relative file }


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


def fn(name)
  puts "num_users with name #{name} = #{User.where(first_name:name).count}"
  return User.where(first_name: name).first
end

def ln(name)
  puts "num_users with name #{name} = #{User.where(last_name:name).count}"
  return User.where(last_name: name).first
end

def c(name1, name2)
  puts "#{name1} story_number = #{User.where(first_name: name1).first.state_table.story_number}"
  puts "#{name2} story_number = #{User.where(first_name: name2).first.state_table.story_number}"
end

