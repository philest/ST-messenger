require 'rake'
require 'twilio-ruby'
require 'activerecord-jdbcpostgresql-adapter' if RUBY_PLATFORM == 'java'
require 'sequel'

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel"
    Sequel.extension :migration
    db = Sequel.connect(ENV.fetch("DATABASE_URL"))
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "db/migrations")
    end
  end
end


# adds the people who are new to the database, returns a list of user rows of people to send texts to
namespace :enrollment do

	desc "Sends quailtime link text."
	task :send_enrollment_text, :csv_file do |t, args|
		csv_file = args[:csv_file]
		puts "#{csv_file}" if csv_file
		if csv_file
			to_enroll = CSV.read(csv_file).collect {|user| {user[0] => user[1]}}
		else
			to_enroll = {"David" => "+18186897323", "Aubrey" => "+13013328953", "Phil" => "+15612125831"}

			to_enroll = {"David" => "+18186897323"}
		end

		account_sid = ENV["TW_ACCOUNT_SID"]
		auth_token = ENV["TW_AUTH_TOKEN"]

		client = Twilio::REST::Client.new account_sid, auth_token
		from = "+12032023505" # Your Twilio number

		# db = Sequel.connect(ENV['DATABASE_URL'], :sslmode => 'require')
		# users = db[:users]

		to_enroll.each do |key, value|
			client.account.messages.create(
				:from => from,
				:to => value,
				:body => "Hi #{key}, welcome to StoryTime!\nm.me/quailtime"
			)
			puts "Sent message to #{key}"
		end

=begin
		to_enroll.each do |name, number|
			# if the user is not in the database at all....
			if users.where(:phone => number).empty?
				users.insert(:name => name, :phone => number)

				client.account.messages.create(
					:from => from,
					:to => value,
					:body => "Hi #{key}, welcome to StoryTime!\nm.me/quailtime"
				)
				puts "Sent message to #{key}"
			else
				puts "#{key} already exists in the database, job terminated."
			end
		end
=end

	end # of task

end # of namespace


