module Birdv
  module DSL
    class Curricula
    	@@curricula = {}
      
      def self.load(dir="../curriculum_versions", absolute=false)
        require 'csv'
        @@curricula = {}

        # TODO: ensure ending '/'
        if !absolute
          file_path = "#{File.expand_path(File.dirname(__FILE__))}/#{dir}/*"
        else
          file_path = "#{dir}*"
        end
        # using a hash to ensure the correct ordering of the curriculum versions
        Dir.glob(file_path).each do |f|
          puts f
          CSV.foreach(f, headers:true, header_converters: :symbol, :converters => :all) do |row|
            curr_version = File.basename(f, ".csv").to_i
            @@curricula[curr_version] ||= []
            @@curricula[curr_version] << row
          end
        end
      end
      
      def self.curricula
        @@curricula
      end


      def curricula
        @@curricula
      end

      def self.get_version(version_num)
      	return @@curricula[version_num]
      end
    end #--> class Curricula
  end #--> module DSL
end #--> module Birdv
