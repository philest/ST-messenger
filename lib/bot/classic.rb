require_relative "test.rb"

puts_file

$curriculum_versions.each do |version, rows|
	rows.each do |row|
		puts row[:name]
		puts row[:num_pages]
		puts row[:url]

	end
end
