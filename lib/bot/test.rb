require 'csv'
# Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../curriculum_versions/*").each do |f|
#   CSV.foreach(f, headers:true, header_converters: :symbol, :converters => :all) do |row|
#     day_number = File.basename(f, ".csv").to_i
#     @@curriculum_versions[day_number] ||= []
#     @@curriculum_versions[day_number] << row
#   end
# end

class Test

	puts "starting up"

@@d = "dcf"
puts @@d

	def self.load_x
		return "we have come to take your sheep"
	end
	@@x = load_x

	def self.x
		@@x
	end

	      def self.load_curriculum_versions
        require 'csv'
        versions = {}
        Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/../curriculum_versions/*").each do |f|
          CSV.foreach(f, headers:true, header_converters: :symbol, :converters => :all) do |row|
            day_number = File.basename(f, ".csv").to_i
            versions[day_number] ||= []
            versions[day_number] << row
          end
        end
        return versions
      end


       @@curriculum_versions = load_curriculum_versions

       def self.curriculum_versions() @@curriculum_versions; end
       def curriculum_versions() @@curriculum_versions; end


end

puts Test.curriculum_versions

puts Test.new.curriculum_versions


